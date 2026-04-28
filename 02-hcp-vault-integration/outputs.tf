# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "vault_auth_method_path" {
  description = "Path of the JWT auth method in Vault"
  value       = vault_jwt_auth_backend.eks.path
}

output "vault_policy_name" {
  description = "Name of the Vault policy created"
  value       = vault_policy.demo_kv_read.name
}

output "kubernetes_namespace" {
  description = "Namespace where the secret is synced"
  value       = kubernetes_namespace.demo_app.metadata[0].name
}

output "synced_secret_name" {
  description = "Name of the Kubernetes Secret created by VSO"
  value       = "${var.demo_secret_path}-secret"
}

output "vso_helm_release_status" {
  description = "Status of the VSO Helm release"
  value       = helm_release.vault_secrets_operator.status
}
