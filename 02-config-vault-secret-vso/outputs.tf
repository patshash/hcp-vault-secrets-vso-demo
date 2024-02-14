output "kubernetes_namespace" {
  value = kubernetes_namespace.demo-app.name
}

output "app_name" {
  value = var.app_name
}
