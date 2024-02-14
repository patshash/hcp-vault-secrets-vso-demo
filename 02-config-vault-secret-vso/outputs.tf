output "kubernetes_namespace" {
  value = kubernetes_namespace.demo-app.metadata[0].name
}

output "app_name" {
  value = var.app_name
}
