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
  name = var.tfc_project_name
}

data "tfe_variable_set" "HCP_IAM_Service_Principal" {
  name         = var.var_set_HCP_IAM_SP
  organization = data.tfe_organization.this.name
}

data "tfe_variable_set" "aws-credentials" {
  name         = var.var_set_aws_credential
  organization = data.tfe_organization.this.name
}

resource "tfe_project_variable_set" "HCP_IAM_Service_Principal" {
  project_id    = tfe_project.tfe_project.id
  variable_set_id = data.tfe_variable_set.HCP_IAM_Service_Principal.id
}

resource "tfe_project_variable_set" "aws-credentials" {
  project_id    = tfe_project.tfe_project.id
  variable_set_id = data.tfe_variable_set.aws-credentials.id
}

data "tfe_oauth_client" "client" {
  organization = data.tfe_organization.this.name
  name         = var.tfc_vcs_name
}

resource "tfe_workspace" "deploy_eks" {
  name                 = "01_deploy_eks"
  organization         = data.tfe_organization.this.name
  project_id           = tfe_project.tfe_project.id
  queue_all_runs       = false
  working_directory    = "01-deploy-eks"
  vcs_repo {
    branch             = "main"
    identifier         = var.git_repo
    oauth_token_id     = data.tfe_oauth_client.client.oauth_token_id
  }
}

resource "tfe_workspace" "config-vault-secret-vso" {
  name                 = "02-config-vault-secret-vso"
  organization         = data.tfe_organization.this.name
  project_id           = tfe_project.tfe_project.id
  queue_all_runs       = false
  working_directory    = "02-config-vault-secret-vso"
  vcs_repo {
    branch             = "main"
    identifier         = var.git_repo
    oauth_token_id     = data.tfe_oauth_client.client.oauth_token_id
  }
}

resource "tfe_workspace" "sync-secret-to-k8" {
  name                 = "03-sync-secret-to-k8"
  organization         = data.tfe_organization.this.name
  project_id           = tfe_project.tfe_project.id
  queue_all_runs       = false
  working_directory    = "03-sync-secret-to-k8"
  vcs_repo {
    branch             = "main"
    identifier         = var.git_repo
    oauth_token_id     = data.tfe_oauth_client.client.oauth_token_id
  }
}
