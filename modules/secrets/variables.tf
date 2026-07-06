variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "eso_namespace" {
  description = "Namespace the External Secrets Operator itself runs in"
  type        = string
  default     = "external-secrets"
}

variable "eso_service_account_name" {
  type    = string
  default = "external-secrets"
}

variable "rds_endpoint" {
  type = string
}

variable "rds_port" {
  type = number
}

variable "rds_db_name" {
  type = string
}

variable "rds_master_username" {
  type = string
}

variable "rds_master_password_secret_arn" {
  type = string
}

variable "redis_primary_endpoint" {
  type = string
}

variable "redis_port" {
  type = number
}

variable "sqs_queue_url" {
  type = string
}

variable "namespace" {
  description = "Kubernetes namespace the Stagecraft services run in — used to build in-cluster DNS names"
  type        = string
}

variable "github_client_id" {
  type      = string
  sensitive = true
}

variable "github_client_secret" {
  type      = string
  sensitive = true
}

variable "github_webhook_secret" {
  type      = string
  sensitive = true
}

variable "github_app_id" {
  type      = string
  sensitive = true
}

variable "github_app_private_key" {
  type      = string
  sensitive = true
}

variable "github_app_slug" {
  type = string
}

variable "allowed_org" {
  type = string
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "token_encryption_key" {
  type      = string
  sensitive = true
}

variable "internal_api_key" {
  type      = string
  sensitive = true
}

variable "nextauth_secret" {
  type      = string
  sensitive = true
}

variable "ses_from_email" {
  type = string
}

variable "frontend_url" {
  type = string
}

variable "bedrock_model_id" {
  type = string
}

variable "bedrock_api_key" {
  description = "Bedrock long/short-term API key (bearer token) — takes priority over IRSA-based invoke when set. See app/services/bedrock_client.py in api and worker."
  type        = string
  default     = ""
  sensitive   = true
}
