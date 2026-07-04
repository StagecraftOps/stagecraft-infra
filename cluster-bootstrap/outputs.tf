output "namespace" {
  value = kubernetes_namespace.stagecraft.metadata[0].name
}

output "eso_namespace" {
  value = kubernetes_namespace.external_secrets.metadata[0].name
}

output "lb_controller_release_status" {
  value = helm_release.aws_load_balancer_controller.status
}

output "external_secrets_release_status" {
  value = helm_release.external_secrets.status
}
