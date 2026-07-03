variable "name" {
  description = "Name prefix for networking resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across"
  type        = number
  default     = 2
}

variable "cluster_name" {
  description = "EKS cluster name, used to tag subnets for cluster/ELB auto-discovery"
  type        = string
}
