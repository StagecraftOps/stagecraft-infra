locals {
  stage1 = data.terraform_remote_state.stage1.outputs
}

resource "kubernetes_namespace" "stagecraft" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of" = "stagecraft"
    }
  }
}

# Installs the AWS Load Balancer Controller so the Ingress resources in
# stagecraft-helm can actually provision an ALB. Verify the chart's current
# values.yaml (helm show values eks/aws-load-balancer-controller) matches
# these `set` blocks before applying — chart versions do shift argument names.
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "clusterName"
    value = local.stage1.cluster_name
  }

  # Explicit vpcId/region — the controller otherwise auto-discovers these via
  # EC2 instance metadata (IMDS), which times out from pod network namespace
  # when the node's IMDS hop limit is 1 (pods aren't hostNetwork, so the
  # request needs 2 hops and gets dropped). Skips IMDS entirely.
  set {
    name  = "vpcId"
    value = local.stage1.vpc_id
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = local.stage1.lb_controller_role_arn
  }
}

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = var.eso_namespace
  }
}

# Installs the External Secrets Operator, which syncs the 5 Secrets Manager
# entries stage 1 created (module.secrets) into real Kubernetes Secrets —
# no raw credential values pass through this Terraform stage at all. Verify
# the chart's current values.yaml (helm show values external-secrets/external-secrets)
# matches these `set` blocks before applying.
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = kubernetes_namespace.external_secrets.metadata[0].name
  create_namespace = false

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = var.eso_service_account_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = local.stage1.eso_role_arn
  }
}

# EBS CSI driver — an AWS-authored EKS addon (unlike the two community
# controllers above, so it's installed via aws_eks_addon rather than
# helm_release). This is the platform's first dynamic volume provisioner;
# Neo4j is the first workload that needs a PersistentVolumeClaim.
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = local.stage1.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = local.stage1.ebs_csi_role_arn
  resolve_conflicts_on_update = "OVERWRITE"
}

# gp3 StorageClass for anything needing a PVC (currently just Neo4j).
# WaitForFirstConsumer so the volume provisions in the same AZ as whichever
# node the pod actually schedules to.
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
  }
  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  parameters = {
    type = "gp3"
  }

  depends_on = [aws_eks_addon.ebs_csi]
}
