
terraform {
  required_providers {
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

provider "hcp" {}
# Get HCP ORG ID
data "hcp_organization" "this" {
}

# Get HCP Project ID
data "hcp_project" "this" {
}

# Get details needed to authenticate to Kubernetes
data "tfe_outputs" "01-deploy-eks" {
  organization = "pcarey-org"
  workspace = "01-deploy-eks"
}

data "tfe_outputs" "02-config-vault-secret-vso" {
  organization = "pcarey-org"
  workspace = "02-config-vault-secret-vso"
}

data "aws_eks_cluster" "deploy-eks" {
  name = data.tfe_outputs.01-deploy-eks.values.cluster_name
}

data "aws_eks_cluster_auth" "deploy-eks" {
  name = data.tfe_outputs.01-deploy-eks.values.cluster_name
}


provider "kubernetes" {
  host                   = data.tfe_outputs.01-deploy-eks.values.cluster_endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.01-deploy-eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.01-deploy-eks.token
}

# Configure VSO to use HCPAuth. 
resource "kubernetes_manifest" "hcpauth_default" {
  manifest = {
    "apiVersion" = "secrets.hashicorp.com/v1beta1"
    "kind" = "HCPAuth"
    "metadata" = {
      "name" = "default"
      "namespace" = "vault-secrets-operator-system"
    }
    "spec" = {
      "organizationID" = data.hcp_organization.this.resource_id
      "projectID" = data.hcp_project.this.resource_id
      "servicePrincipal" = {
        "secretRef" = "vso-sp"
      }
    }
  }
}

# Create a K8 Secret from HCP Vault Secret "AppName"
resource "kubernetes_manifest" "hcpvaultsecretsapp_web_application" {
  manifest = {
    "apiVersion" = "secrets.hashicorp.com/v1beta1"
    "kind" = "HCPVaultSecretsApp"
    "metadata" = {
      "name" = "web-application"
      "namespace" = data.tfe_outputs.02-config-vault-secret-vso.values.kubernetes_namespace
    }
    "spec" = {
      "appName" = data.tfe_outputs.02-config-vault-secret-vso.values.app_name
      "destination" = {
        "create" = true
        "labels" = {
          "hvs" = "true"
        }
        "name" = "web-application"
      }
      "refreshAfter" = "1h"
    }
  }
}
