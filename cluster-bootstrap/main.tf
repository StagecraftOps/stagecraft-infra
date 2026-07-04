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
