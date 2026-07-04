variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "namespace" {
  type    = string
  default = "stagecraft"
}

variable "frontend_url" {
  type    = string
  default = "https://stagecraft.example.com"
}

variable "bedrock_model_id" {
  type    = string
  default = "anthropic.claude-sonnet-4-6"
}

# --- Everything below is a real secret with no safe default. Left empty on
# purpose (per explicit instruction) — fill these in via a gitignored
# terraform.tfvars (or -var-file) before applying, never commit real values. ---

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
  description = "GitHub App slug (lowercase, hyphens) — used to build the install URL"
  type        = string
  default     = ""
}

variable "allowed_org" {
  description = "GitHub org stagecraft-mcp restricts tool calls to"
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
  description = "Leave empty to leave SES_ENABLED effectively off"
  type        = string
  default     = ""
}
