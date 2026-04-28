# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "vault_address" {
  description = "Full URL of the HCP Vault Dedicated cluster (e.g., https://vault-cluster.vault.xxxxx.aws.hashicorp.cloud:8200)"
  type        = string
}

variable "vault_token" {
  description = "Admin token for configuring the Vault cluster"
  type        = string
  sensitive   = true
}

variable "vault_namespace" {
  description = "Vault namespace (HCP Vault Dedicated uses admin by default)"
  type        = string
  default     = "admin"
}

variable "region" {
  description = "AWS region (must match 01-deploy-eks)"
  type        = string
  default     = "ap-southeast-2"
}

variable "tfc_org" {
  description = "TFC organization name"
  type        = string
  default     = "pcarey-org"
}

variable "tfc_workspace_eks" {
  description = "TFC workspace name for 01-deploy-eks outputs"
  type        = string
  default     = "01_deploy_eks"
}

variable "demo_secret_path" {
  description = "KV v2 mount path"
  type        = string
  default     = "demo-kv"
}

variable "demo_secret_name" {
  description = "Secret name within KV v2"
  type        = string
  default     = "demo-app/config"
}

variable "demo_secret_data" {
  description = "Key-value pairs for the demo secret"
  type        = map(string)
  default = {
    username = "demo-user"
    password = "sup3rS3cret!"
  }
  sensitive = true
}

variable "kubernetes_namespace" {
  description = "Namespace for the demo app and synced secret"
  type        = string
  default     = "demo-app"
}
