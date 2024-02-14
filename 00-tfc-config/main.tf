terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.82.0"
    }
    tfe = {
      version = "~> 0.52.0"
    }
  }
}
provider "tfe" {
  organization = var.tfc_org
}

data "tfe_organization" "this" {
}

resource "tfe_project" "tfe_project" {
  organization = data.tfe_organization.this.name
  name = "vault-secret-demo"
}

data "tfe_oauth_client" "client" {
  organization = data.tfe_organization.this.name
  name         = "Hashi github acc"
}

resource "tfe_workspace" "parent" {
  name                 = "parent-ws"
  organization         = data.tfe_organization.this.name
  queue_all_runs       = false
  vcs_repo {
    branch             = "main"
    identifier         = "my-org-name/vcs-repository"
    oauth_token_id     = data.tfe_oauth_client.client.oauth_token_id
  }
}

