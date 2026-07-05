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
  value = module.vpc.vpc_id
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_port" {
  value = module.rds.port
}

output "rds_db_name" {
  value = module.rds.db_name
}

output "rds_master_username" {
  value = module.rds.master_username
}

output "rds_master_password_secret_arn" {
  description = "Secrets Manager ARN — stage 2 reads the actual password from here, it's never a plain Terraform output"
  value       = module.rds.master_password_secret_arn
}

output "redis_primary_endpoint" {
  value = module.elasticache.primary_endpoint
}

output "redis_port" {
  value = module.elasticache.port
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "sqs_queue_arn" {
  value = module.sqs.queue_arn
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

output "ebs_csi_role_arn" {
  value = module.iam.ebs_csi_role_arn
}

output "eso_role_arn" {
  description = "IRSA role the External Secrets Operator (stage 2) uses to read the secrets below"
  value       = module.secrets.eso_role_arn
}

output "api_secret_name" {
  value = module.secrets.api_secret_name
}

output "worker_secret_name" {
  value = module.secrets.worker_secret_name
}

output "webhook_secret_name" {
  value = module.secrets.webhook_secret_name
}

output "mcp_secret_name" {
  value = module.secrets.mcp_secret_name
}

output "frontend_secret_name" {
  value = module.secrets.frontend_secret_name
}
