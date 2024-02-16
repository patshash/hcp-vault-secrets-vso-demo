## Vault Secret Operator and Vault Secrets Demo
This repository will deploy a demo Vault Secrets Operator running on EKS and sync Secrets from HCP Vault Secrets. 

#### Pre-Requisites:
* HCP IAM Service Principal with ADMIN permissions
* AWS Access Credentials.
* VCS Connection from TFC to Github with access to this repo.

### Step 00
Start with 00-tfc-config to configure TFC workspaces. 
You will need to populate the following variables:
* tfc_org - The name of your already setup TFC Organisation
* tfc_project_name - To be created
* git_repo - Where this repo is located
* var_set_HCP_IAM_SP - The name of the Variable set with the HCP IAM Admin details (Environment Variable)
* var_set_aws_credentials - The name of the Variable set with the AWS details (Environment Variable)
* tfc_vcs_name - The name of the VCS connection between TFC and this repo

Terraform expects to find the HCP IAM Service Principal and AWS Credentials in a Variable Set. As these will be attached to the new Project.

This will create a TFC Project in your Organisation and three workspaces.
Workspaces;
* 01_deploy_eks
* 02-config-vault-secret-vso
* 03-sync-secret-to-k8

### Step 1
Once the workspaces are created, move to 01-deploy-eks workspace. 
Update the variable file as follows
* region - The AWS region you wish to deploy the EKS cluster to.

You may wish to interact with the EKS Cluster once deployed and you will required the aws cli and kubectl tools. 
Use the Terraform Outputs from this workspace on your terminal and run the following command:
`aws eks update-kubeconfig  --region {region}  --name {cluster_name}     --alias={cluster_name}`


### Step 2
Once the workspaces are created, move to 02-config-vault-secret-vso
This workspace will install Vault Secrets Operator and create a new HCP Service Principal, HCP Vault Secrets Application and Secret.

Uupdate the Variables as follows:
* app_name - The new Vault Secrets Application to create
* kubernetes_namespace - The Kubernetes Namespace to create and sync secrets to.

By default the secret Key will be "example_secret" with the value "hashi123".

### Step 3
Finally, move to 03-sync-secret-to-k8
This will create CRD values for Vault Secret Operator to sync secrets. 

No variable changes are required at this point. Terraform will create a new CRD in the new Kuberenetes Namespace and sync all secrets from the new Vault Secrets application.
The default name for this secret is "web-application"
