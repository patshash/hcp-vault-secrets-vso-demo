# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {

  cloud {
    workspaces {
      name = "hcp-vault-integration"
    }
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.52"
    }
  }

  required_version = "~> 1.3"
}
