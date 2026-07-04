output "api_secret_name" {
  value = aws_secretsmanager_secret.api.name
}

output "worker_secret_name" {
  value = aws_secretsmanager_secret.worker.name
}

output "webhook_secret_name" {
  value = aws_secretsmanager_secret.webhook.name
}

output "mcp_secret_name" {
  value = aws_secretsmanager_secret.mcp.name
}

output "frontend_secret_name" {
  value = aws_secretsmanager_secret.frontend.name
}

output "eso_role_arn" {
  value = aws_iam_role.eso.arn
}
