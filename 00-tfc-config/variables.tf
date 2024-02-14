variable "hcp_client_id" {
  type = string
  default = ""
  description = "Tag used to define the purpose of the deployment"
}

variable "hcp_client_secret" {
  type = string
  default = ""
  description = "Tag used to define the purpose of the deployment"
}

variable "tfc_org" {
  type = string
  default = "pcarey-org"
  description = "Unique ID for the Orgaisation in TFC"
}

variable "tfc_project_name" {
  type = string
  default = "vault-secret-demo"
  description = "Name for the Project in TFC"
}

variable "git_repo" {
  type = string
  default = "patshash/hcp-vault-secrets-vso-demo"
  description = "Repo name to map to workspaces TFC"
}

variable "var_set_HCP_IAM_SP" {
  type = string
  default = "HCP_IAM_Service_Principal"
  description = "Variable Set HCP Service Principal name for the access to HCP"
}

variable "var_set_aws_credential" {
  type = string
  default = "aws-credentials"
  description = "Variable set name with AWS credentials"
}

variable "tfc_vcs_name" {
  type = string
  default = "Hashi github acc"
  description = "VCS connection to use in TFC"
}
