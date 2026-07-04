variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnets for the Redis subnet group"
  type        = list(string)
}

variable "allowed_security_group_id" {
  description = "Security group allowed to connect on the Redis port (the EKS node security group)"
  type        = string
}

variable "engine_version" {
  type    = string
  default = "7.1"
}

variable "node_type" {
  type    = string
  default = "cache.t4g.micro"
}

variable "num_cache_clusters" {
  description = "1 = single node, no automatic failover; 2+ = primary + replica(s) with automatic failover"
  type        = number
  default     = 1
}
