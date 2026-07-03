output "webhook_role_arn" {
  value = aws_iam_role.webhook.arn
}

output "worker_role_arn" {
  value = aws_iam_role.worker.arn
}

output "api_role_arn" {
  value = aws_iam_role.api.arn
}

output "lb_controller_role_arn" {
  value = aws_iam_role.lb_controller.arn
}
