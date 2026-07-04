variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name prefix for every resource this stack creates (EKS cluster, RDS, Redis, SQS, IAM roles)"
  type        = string
  default     = "stagecraft"
}

variable "kubernetes_version" {
  type    = string
  default = "1.30"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "namespace" {
  description = "Kubernetes namespace the Stagecraft services run in (must match stagecraft-helm)"
  type        = string
  default     = "stagecraft"
}

variable "kb_s3_bucket_arn" {
  description = "ARN of the Bedrock Knowledge Base S3 source bucket (empty string to skip granting worker access)"
  type        = string
  default     = ""
}

# --- RDS (Postgres) ---

variable "rds_engine_version" {
  description = "Must be >= 15.2 for pgvector support — verify current availability before applying"
  type        = string
  default     = "16.4"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "rds_backup_retention_days" {
  type    = number
  default = 7
}

variable "rds_skip_final_snapshot" {
  description = "Set false for anything beyond a demo"
  type        = bool
  default     = true
}

# --- ElastiCache (Redis) ---

variable "redis_engine_version" {
  type    = string
  default = "7.1"
}

variable "redis_node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "redis_num_cache_clusters" {
  description = "1 = single node; 2+ = primary + replica(s) with automatic failover"
  type        = number
  default     = 1
}

# --- Per-service secrets (stored in Secrets Manager here, synced into k8s
# Secrets by the External Secrets Operator in stage 2 — never touch the
# cluster directly, and never sit in a stage-2 tfvars file). Everything
# below has no safe default — fill in via a gitignored terraform.tfvars. ---

variable "github_client_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "github_client_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "github_webhook_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "github_app_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "github_app_private_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "github_app_slug" {
  description = "GitHub App slug (lowercase, hyphens) — used to build the install URL. Not secret, but kept alongside the rest for convenience."
  type        = string
  default     = ""
}

variable "allowed_org" {
  description = "GitHub org stagecraft-mcp restricts tool calls to. Not secret."
  type        = string
  default     = ""
}

variable "secret_key" {
  description = "JWT signing key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "token_encryption_key" {
  description = "Fernet key for encrypting stored GitHub OAuth tokens"
  type        = string
  default     = ""
  sensitive   = true
}

variable "internal_api_key" {
  description = "Shared secret gating /internal/* routes between api, worker, and mcp"
  type        = string
  default     = ""
  sensitive   = true
}

variable "nextauth_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ses_from_email" {
  description = "Leave empty to leave SES_ENABLED effectively off. Not secret."
  type        = string
  default     = ""
}

variable "frontend_url" {
  type    = string
  default = "https://stagecraft.example.com"
}

variable "bedrock_model_id" {
  type    = string
  default = "anthropic.claude-sonnet-4-6"
}
