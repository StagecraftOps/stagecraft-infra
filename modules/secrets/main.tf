resource "random_password" "neo4j" {
  length  = 24
  special = false
}

locals {
  oidc_issuer_host = replace(var.oidc_provider_url, "https://", "")

  worker_internal_url = "http://stagecraft-worker.${var.namespace}.svc.cluster.local:8080"
  mcp_github_url      = "http://stagecraft-mcp.${var.namespace}.svc.cluster.local:8010/sse"

  stagecraft_api_url = "http://stagecraft-api.${var.namespace}.svc.cluster.local:80"
  neo4j_uri          = "bolt://stagecraft-neo4j.${var.namespace}.svc.cluster.local:7687"

  api_payload = {
    DATABASE_URL           = "postgresql+asyncpg://${var.rds_master_username}:${data.aws_secretsmanager_secret_version.rds_master_password.secret_string}@${var.rds_endpoint}:${var.rds_port}/${var.rds_db_name}"
    REDIS_URL              = "rediss://${var.redis_primary_endpoint}:${var.redis_port}/0"
    GITHUB_CLIENT_ID       = var.github_client_id
    GITHUB_CLIENT_SECRET   = var.github_client_secret
    GITHUB_WEBHOOK_SECRET  = var.github_webhook_secret
    GITHUB_APP_ID          = var.github_app_id
    GITHUB_APP_PRIVATE_KEY = var.github_app_private_key
    GITHUB_APP_SLUG        = var.github_app_slug
    SECRET_KEY             = var.secret_key
    TOKEN_ENCRYPTION_KEY   = var.token_encryption_key
    INTERNAL_API_KEY       = var.internal_api_key
    SQS_QUEUE_URL          = var.sqs_queue_url
    WORKER_INTERNAL_URL    = local.worker_internal_url
    BEDROCK_MODEL_ID       = var.bedrock_model_id
    BEDROCK_CHAT_MODEL_ID  = var.bedrock_model_id
    BEDROCK_API_KEY        = var.bedrock_api_key
    NEO4J_URI              = local.neo4j_uri
    NEO4J_USER             = "neo4j"
    NEO4J_PASSWORD         = random_password.neo4j.result
  }

  worker_payload = {
    DATABASE_URL           = "postgresql://${var.rds_master_username}:${data.aws_secretsmanager_secret_version.rds_master_password.secret_string}@${var.rds_endpoint}:${var.rds_port}/${var.rds_db_name}"
    REDIS_URL              = "rediss://${var.redis_primary_endpoint}:${var.redis_port}/0"
    SQS_QUEUE_URL          = var.sqs_queue_url
    GITHUB_APP_ID          = var.github_app_id
    GITHUB_APP_PRIVATE_KEY = var.github_app_private_key
    SECRET_KEY             = var.secret_key
    TOKEN_ENCRYPTION_KEY   = var.token_encryption_key
    INTERNAL_API_KEY       = var.internal_api_key
    BEDROCK_MODEL_ID       = var.bedrock_model_id
    BEDROCK_API_KEY        = var.bedrock_api_key
    FRONTEND_URL           = var.frontend_url
    SES_FROM_EMAIL         = var.ses_from_email
    MCP_GITHUB_URL         = local.mcp_github_url
    NEO4J_URI              = local.neo4j_uri
    NEO4J_USER             = "neo4j"
    NEO4J_PASSWORD         = random_password.neo4j.result
  }

  webhook_payload = {
    GITHUB_WEBHOOK_SECRET = var.github_webhook_secret
    SQS_QUEUE_URL         = var.sqs_queue_url
  }

  mcp_payload = {
    GITHUB_APP_ID          = var.github_app_id
    GITHUB_APP_PRIVATE_KEY = var.github_app_private_key
    ALLOWED_ORG            = var.allowed_org
    INTERNAL_API_KEY       = var.internal_api_key
    STAGECRAFT_API_URL     = local.stagecraft_api_url
  }

  frontend_payload = {
    GITHUB_CLIENT_ID     = var.github_client_id
    GITHUB_CLIENT_SECRET = var.github_client_secret
    NEXTAUTH_SECRET      = var.nextauth_secret
  }
}

data "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id = var.rds_master_password_secret_arn
}

resource "aws_secretsmanager_secret" "api" {
  name                    = "${var.cluster_name}-api-secrets"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "api" {
  secret_id     = aws_secretsmanager_secret.api.id
  secret_string = jsonencode(local.api_payload)
}

resource "aws_secretsmanager_secret" "worker" {
  name                    = "${var.cluster_name}-worker-secrets"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "worker" {
  secret_id     = aws_secretsmanager_secret.worker.id
  secret_string = jsonencode(local.worker_payload)
}

resource "aws_secretsmanager_secret" "webhook" {
  name                    = "${var.cluster_name}-webhook-secrets"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "webhook" {
  secret_id     = aws_secretsmanager_secret.webhook.id
  secret_string = jsonencode(local.webhook_payload)
}

resource "aws_secretsmanager_secret" "mcp" {
  name                    = "${var.cluster_name}-mcp-secrets"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "mcp" {
  secret_id     = aws_secretsmanager_secret.mcp.id
  secret_string = jsonencode(local.mcp_payload)
}

resource "aws_secretsmanager_secret" "frontend" {
  name                    = "${var.cluster_name}-frontend-secrets"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "frontend" {
  secret_id     = aws_secretsmanager_secret.frontend.id
  secret_string = jsonencode(local.frontend_payload)
}

resource "aws_secretsmanager_secret" "neo4j" {
  name                    = "${var.cluster_name}-neo4j-secrets"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "neo4j" {
  secret_id     = aws_secretsmanager_secret.neo4j.id
  secret_string = jsonencode({ NEO4J_AUTH = "neo4j/${random_password.neo4j.result}" })
}

data "aws_iam_policy_document" "eso_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:${var.eso_namespace}:${var.eso_service_account_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eso" {
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.eso_trust.json
}

resource "aws_iam_role_policy" "eso" {
  name = "secretsmanager-read"
  role = aws_iam_role.eso.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = [
        aws_secretsmanager_secret.api.arn,
        aws_secretsmanager_secret.worker.arn,
        aws_secretsmanager_secret.webhook.arn,
        aws_secretsmanager_secret.mcp.arn,
        aws_secretsmanager_secret.frontend.arn,
        aws_secretsmanager_secret.neo4j.arn,
      ]
    }]
  })
}
