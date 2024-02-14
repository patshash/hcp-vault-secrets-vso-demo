variable "hcp_client_id" {
  type = string
  description = "Tag used to define the purpose of the deployment"
}

variable "hcp_client_secret" {
  type = string
  description = "Tag used to define the purpose of the deployment"
}

variable "app_name" {
  type = string
  default = "new-secret-app-1"
  description = "Unique ID for the Orgaisation in HCP Cloud"
}

variable "kubernetes_namespace" {
  type = string
  default = "demo-app"
  description = "Unique namespace for the demo app"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}
