variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster and prefix for related resources"
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

variable "sqs_queue_arn" {
  description = "ARN of the pre-existing shared SQS queue (stagecraft-webhooks) — provisioned outside this stack"
  type        = string
}

variable "kb_s3_bucket_arn" {
  description = "ARN of the Bedrock Knowledge Base S3 source bucket (empty string to skip granting worker access)"
  type        = string
  default     = ""
}
