output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value     = module.eks.cluster_certificate_authority_data
  sensitive = true
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "webhook_role_arn" {
  value = module.iam.webhook_role_arn
}

output "worker_role_arn" {
  value = module.iam.worker_role_arn
}

output "api_role_arn" {
  value = module.iam.api_role_arn
}

output "lb_controller_role_arn" {
  value = module.iam.lb_controller_role_arn
}
