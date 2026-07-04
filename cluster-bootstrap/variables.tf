variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "namespace" {
  type    = string
  default = "stagecraft"
}

variable "eso_namespace" {
  description = "Must match modules/secrets' eso_namespace in stage 1 (the trust policy is scoped to this namespace)"
  type        = string
  default     = "external-secrets"
}

variable "eso_service_account_name" {
  description = "Must match modules/secrets' eso_service_account_name in stage 1"
  type        = string
  default     = "external-secrets"
}
