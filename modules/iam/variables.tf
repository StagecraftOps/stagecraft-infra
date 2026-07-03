variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster's IAM OIDC provider (from the eks module)"
  type        = string
}

variable "oidc_provider_url" {
  description = "Issuer URL of the EKS cluster's OIDC provider, without the https:// prefix"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace the Stagecraft services run in"
  type        = string
  default     = "stagecraft"
}

variable "sqs_queue_arn" {
  description = "ARN of the shared SQS queue (stagecraft-webhooks)"
  type        = string
}

variable "kb_s3_bucket_arn" {
  description = "ARN of the Bedrock Knowledge Base S3 source bucket (empty string to skip granting access)"
  type        = string
  default     = ""
}
