terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.2"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.82.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tfe = {
      version = "~> 0.52.0"
    }
  }
}

provider "aws" {
  region = data.tfe_outputs.deploy-eks.values.region
}

provider "helm" {
  kubernetes {
    host                   = data.tfe_outputs.deploy-eks.values.cluster_endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.deploy-eks.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.tfe_outputs.deploy-eks.values.cluster_name]
      command     = "aws"
    }
  }
}

provider "hcp" {}


# Get HCP ORG ID
data "hcp_organization" "this" {
}

# Get HCP Project ID
data "hcp_project" "this" {
}

# Get details about the Kube cluster needed to authenticate
data "tfe_outputs" "deploy-eks" {
  organization = "pcarey-org"
  workspace = "01_deploy_eks"
}

data "aws_eks_cluster" "deploy-eks" {
  name = data.tfe_outputs.deploy-eks.values.cluster_name
}

data "aws_eks_cluster_auth" "deploy-eks" {
  name = data.tfe_outputs.deploy-eks.values.cluster_name
}

provider "kubernetes" {
  host                   = data.tfe_outputs.deploy-eks.values.cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.deploy-eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.deploy-eks.token
}

# Create new HCP Service Principal for VSO to access Vault Secrets
resource "hcp_service_principal" "vso_service_principal" {
  name = "vso-sp"
}
# Create new HCP Service Principal Key for VSO
resource "hcp_service_principal_key" "vso_service_principal_key" {
  service_principal = hcp_service_principal.vso_service_principal.resource_name
}

# Create a new Application in Vault Secrets for our secret.
resource "hcp_vault_secrets_app" "example" {
  app_name    = var.app_name
  description = "My new secret app!"
}

# Add a secret.
resource "hcp_vault_secrets_secret" "example" {
  app_name     = hcp_vault_secrets_app.example.app_name
  secret_name  = "example_secret"
  secret_value = "hashi123"
}


# Assign role to new SP and map to our application
resource "hcp_project_iam_binding" "vso_service_principal_role" {
  project_id   = data.hcp_project.this.resource_id
  principal_id = hcp_service_principal.vso_service_principal.resource_id
  role         = "roles/contributor"
}

# Install VSO from Helm into new namespace for VSO
resource "helm_release" "vault-secrets-operator" {
  name       = "vault-secrets-operator"
  namespace  = "vault-secrets-operator-system"
  create_namespace = "true"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault-secrets-operator"
  wait = true
  timeout = 500

}

# Store new HCP Service Principal details in K8 secret for VSO to consume.
resource "kubernetes_secret" "vso-sp" {
  metadata {
    name = "vso-sp"
    #    namespace = "vault-secrets-operator-system"
    namespace = kubernetes_namespace.demo-app.metadata[0].name
  }
  data = {
    clientID = hcp_service_principal_key.vso_service_principal_key.client_id
    clientSecret = hcp_service_principal_key.vso_service_principal_key.client_secret

  }
  type = "Opaque"
}

# Create a namespace for our demo application
resource "kubernetes_namespace" "demo-app" {
  metadata {
    annotations = {
      name = "demo-annotation"
    }

    labels = {
      mylabel = "demo"
    }

    name = var.kubernetes_namespace
  }
}

