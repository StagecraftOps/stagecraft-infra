locals {
  stage1 = data.terraform_remote_state.stage1.outputs
}

data "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id = local.stage1.rds_master_password_secret_arn
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

# --- Per-service secrets ---
# Computed values (DATABASE_URL, REDIS_URL, SQS_QUEUE_URL) are derived from
# stage 1 outputs. Everything else is a variable with an empty default per
# explicit instruction — fill in via terraform.tfvars (gitignored) before
# applying, then re-run `terraform apply` here to update the Secret in place.

resource "kubernetes_secret" "api" {
  metadata {
    name      = "stagecraft-api-secrets"
    namespace = kubernetes_namespace.stagecraft.metadata[0].name
  }
  type = "Opaque"
  data = {
    DATABASE_URL = "postgresql+asyncpg://${local.stage1.rds_master_username}:${data.aws_secretsmanager_secret_version.rds_master_password.secret_string}@${local.stage1.rds_endpoint}:${local.stage1.rds_port}/${local.stage1.rds_db_name}"
    REDIS_URL    = "rediss://${local.stage1.redis_primary_endpoint}:${local.stage1.redis_port}/0"

    GITHUB_CLIENT_ID       = var.github_client_id
    GITHUB_CLIENT_SECRET   = var.github_client_secret
    GITHUB_WEBHOOK_SECRET  = var.github_webhook_secret
    GITHUB_APP_ID          = var.github_app_id
    GITHUB_APP_PRIVATE_KEY = var.github_app_private_key
    GITHUB_APP_SLUG        = var.github_app_slug
    SECRET_KEY             = var.secret_key
    TOKEN_ENCRYPTION_KEY   = var.token_encryption_key
    INTERNAL_API_KEY       = var.internal_api_key
    WORKER_INTERNAL_URL    = "http://stagecraft-worker.${var.namespace}.svc.cluster.local:8080"
    BEDROCK_MODEL_ID       = var.bedrock_model_id
    BEDROCK_CHAT_MODEL_ID  = var.bedrock_model_id
  }
}

resource "kubernetes_secret" "worker" {
  metadata {
    name      = "stagecraft-worker-secrets"
    namespace = kubernetes_namespace.stagecraft.metadata[0].name
  }
  type = "Opaque"
  data = {
    DATABASE_URL  = "postgresql://${local.stage1.rds_master_username}:${data.aws_secretsmanager_secret_version.rds_master_password.secret_string}@${local.stage1.rds_endpoint}:${local.stage1.rds_port}/${local.stage1.rds_db_name}"
    REDIS_URL     = "rediss://${local.stage1.redis_primary_endpoint}:${local.stage1.redis_port}/0"
    SQS_QUEUE_URL = local.stage1.sqs_queue_url

    GITHUB_APP_ID          = var.github_app_id
    GITHUB_APP_PRIVATE_KEY = var.github_app_private_key
    SECRET_KEY             = var.secret_key
    TOKEN_ENCRYPTION_KEY   = var.token_encryption_key
    INTERNAL_API_KEY       = var.internal_api_key
    BEDROCK_MODEL_ID       = var.bedrock_model_id
    FRONTEND_URL           = var.frontend_url
    SES_FROM_EMAIL         = var.ses_from_email
    MCP_GITHUB_URL         = "http://stagecraft-mcp.${var.namespace}.svc.cluster.local:8010/sse"
  }
}

resource "kubernetes_secret" "webhook" {
  metadata {
    name      = "stagecraft-webhook-secrets"
    namespace = kubernetes_namespace.stagecraft.metadata[0].name
  }
  type = "Opaque"
  data = {
    GITHUB_WEBHOOK_SECRET = var.github_webhook_secret
    SQS_QUEUE_URL         = local.stage1.sqs_queue_url
  }
}

resource "kubernetes_secret" "mcp" {
  metadata {
    name      = "stagecraft-mcp-secrets"
    namespace = kubernetes_namespace.stagecraft.metadata[0].name
  }
  type = "Opaque"
  data = {
    GITHUB_APP_ID          = var.github_app_id
    GITHUB_APP_PRIVATE_KEY = var.github_app_private_key
    ALLOWED_ORG            = var.allowed_org
    INTERNAL_API_KEY       = var.internal_api_key
    STAGECRAFT_API_URL     = "http://stagecraft-api.${var.namespace}.svc.cluster.local:8000"
  }
}

resource "kubernetes_secret" "frontend" {
  metadata {
    name      = "stagecraft-frontend-secrets"
    namespace = kubernetes_namespace.stagecraft.metadata[0].name
  }
  type = "Opaque"
  data = {
    GITHUB_CLIENT_ID     = var.github_client_id
    GITHUB_CLIENT_SECRET = var.github_client_secret
    NEXTAUTH_SECRET      = var.nextauth_secret
  }
}
