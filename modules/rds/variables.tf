variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnets for the DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_id" {
  description = "Security group allowed to connect on the Postgres port (the EKS node security group)"
  type        = string
}

variable "engine_version" {
  description = "Postgres engine version — must be >= 15.2 for pgvector support. Verify current availability with `aws rds describe-db-engine-versions --engine postgres` before applying."
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "skip_final_snapshot" {
  description = "Set false for anything beyond a demo — true means no snapshot is taken on destroy"
  type        = bool
  default     = true
}

variable "db_name" {
  type    = string
  default = "stagecraft"
}

variable "master_username" {
  type    = string
  default = "stagecraft"
}
