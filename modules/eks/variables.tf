variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS control plane version"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC to deploy the cluster into"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnets, combined with private subnets for the control plane's ENIs"
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
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
