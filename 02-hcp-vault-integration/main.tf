# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# =============================================================================
# Section 1 — Provider Configuration & Data Sources
# =============================================================================

data "tfe_outputs" "deploy_eks" {
  organization = var.tfc_org
  workspace    = var.tfc_workspace_eks
}

provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "deploy_eks" {
  name = data.tfe_outputs.deploy_eks.nonsensitive_values.cluster_name
}

data "aws_eks_cluster_auth" "deploy_eks" {
  name = data.tfe_outputs.deploy_eks.nonsensitive_values.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.deploy_eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.deploy_eks.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.deploy_eks.name]
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.deploy_eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.deploy_eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.deploy_eks.token
}

provider "vault" {
  address   = var.vault_address
  token     = var.vault_token
  namespace = var.vault_namespace
}

# Extract the OIDC provider URL from the EKS cluster
locals {
  oidc_provider_url = data.aws_eks_cluster.deploy_eks.identity[0].oidc[0].issuer
}

# =============================================================================
# Section 2 — Vault Server-Side Configuration
# =============================================================================

# 2.1 — Enable KV v2 secrets engine
resource "vault_mount" "demo_kv" {
  path        = var.demo_secret_path
  type        = "kv"
  options     = { version = "2" }
  description = "KV v2 secrets engine for demo application"
}

# 2.2 — Write a demo secret
resource "vault_kv_secret_v2" "demo_secret" {
  mount = vault_mount.demo_kv.path
  name  = var.demo_secret_name

  data_json = jsonencode(var.demo_secret_data)
}

# 2.3 — Create a Vault policy granting read access to demo-kv
resource "vault_policy" "demo_kv_read" {
  name = "demo-kv-read"

  policy = <<-EOT
    path "${var.demo_secret_path}/data/*" {
      capabilities = ["read"]
    }
    path "${var.demo_secret_path}/metadata/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

# 2.4 — Enable JWT auth method for EKS
resource "vault_jwt_auth_backend" "eks" {
  description        = "JWT auth backend for EKS OIDC"
  path               = "jwt-eks"
  type               = "jwt"
  oidc_discovery_url = local.oidc_provider_url
  bound_issuer       = local.oidc_provider_url
}

# 2.5 — Create a JWT auth role for VSO
resource "vault_jwt_auth_backend_role" "vso_role" {
  backend        = vault_jwt_auth_backend.eks.path
  role_name      = "vso-role"
  token_policies = [vault_policy.demo_kv_read.name]

  bound_audiences = ["https://kubernetes.default.svc.cluster.local"]
  user_claim      = "sub"
  role_type       = "jwt"

  bound_claims = {
    "/kubernetes.io/namespace"           = "vault-secrets-operator-system"
    "/kubernetes.io/serviceaccount/name" = "vault-secrets-operator-controller-manager"
  }
}

# =============================================================================
# Section 3 — Kubernetes Resources
# =============================================================================

# 3.1 — Create demo-app namespace
resource "kubernetes_namespace" "demo_app" {
  metadata {
    name = var.kubernetes_namespace
  }
}

# 3.2 — Install VSO via Helm
resource "helm_release" "vault_secrets_operator" {
  name             = "vault-secrets-operator"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault-secrets-operator"
  namespace        = "vault-secrets-operator-system"
  create_namespace = true

  wait = true

  set {
    name  = "defaultVaultConnection.enabled"
    value = "false"
  }
}

# =============================================================================
# Section 4 — VSO Custom Resources
# =============================================================================

# 4.1 — VaultConnection — tells VSO how to reach the Vault cluster
resource "kubernetes_manifest" "vault_connection" {
  depends_on = [helm_release.vault_secrets_operator]

  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultConnection"

    metadata = {
      name      = "vault-connection"
      namespace = var.kubernetes_namespace
    }

    spec = {
      address       = var.vault_address
      skipTLSVerify = false
    }
  }
}

# 4.2 — VaultAuth — configures JWT auth for VSO
resource "kubernetes_manifest" "vault_auth" {
  depends_on = [kubernetes_manifest.vault_connection]

  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultAuth"

    metadata = {
      name      = "vault-auth"
      namespace = var.kubernetes_namespace
    }

    spec = {
      method    = "jwt"
      mount     = vault_jwt_auth_backend.eks.path
      namespace = var.vault_namespace

      vaultConnectionRef = "vault-connection"

      jwt = {
        serviceAccount = "default"
        audiences      = ["https://kubernetes.default.svc.cluster.local"]

        tokenExpirationSeconds = 600
      }
    }
  }
}

# 4.3 — VaultStaticSecret — syncs KV v2 secret to a Kubernetes Secret
resource "kubernetes_manifest" "vault_static_secret" {
  depends_on = [kubernetes_manifest.vault_auth]

  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultStaticSecret"

    metadata = {
      name      = "${var.demo_secret_path}-secret"
      namespace = var.kubernetes_namespace
    }

    spec = {
      type         = "kv-v2"
      mount        = var.demo_secret_path
      path         = var.demo_secret_name
      refreshAfter = "30s"
      namespace    = var.vault_namespace

      vaultAuthRef = "vault-auth"

      destination = {
        name   = "${var.demo_secret_path}-secret"
        create = true
      }
    }
  }
}
