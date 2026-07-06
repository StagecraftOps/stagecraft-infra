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

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = local.stage1.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = local.stage1.ebs_csi_role_arn
  resolve_conflicts_on_update = "OVERWRITE"
}

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
