output "endpoint" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "master_username" {
  value = aws_db_instance.this.username
}

output "master_password_secret_arn" {
  description = "Secrets Manager ARN holding the master password — stage 2 reads this to build DATABASE_URL"
  value       = aws_secretsmanager_secret.master_password.arn
}

output "security_group_id" {
  value = aws_security_group.this.id
}
