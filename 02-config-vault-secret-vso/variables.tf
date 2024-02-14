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

variable "app_name" {
  type = string
  default = "new-secret-app-1"
  description = "Unique ID for the Orgaisation in HCP Cloud"
}
