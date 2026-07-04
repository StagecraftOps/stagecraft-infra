output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.cluster.arn
}

output "cluster_oidc_issuer_url" {
  description = "Raw issuer URL, https:// prefix included — callers strip it themselves (see modules/iam, modules/secrets)"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "node_security_group_id" {
  description = "The cluster's auto-created security group — EKS-managed node groups without a custom launch template attach node ENIs to this SG automatically"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}
