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
