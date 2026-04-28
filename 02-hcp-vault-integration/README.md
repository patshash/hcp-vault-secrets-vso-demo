# 02-hcp-vault-integration

Deploy the **Vault Secrets Operator (VSO)** on an existing EKS cluster and configure **JWT authentication** to an **HCP Vault Dedicated** cluster. A KV v2 secret is written and synced to Kubernetes as proof of integration.

## Architecture

```
┌──────────────────────┐       JWT Auth        ┌─────────────────────────┐
│   EKS Cluster        │ ───────────────────── │  HCP Vault Dedicated    │
│   (from 01-deploy-eks)│                       │  (existing cluster)     │
│                       │                       │                         │
│  ┌─────────────────┐ │                       │  ┌───────────────────┐  │
│  │ Vault Secrets   │ │  Read KV v2 Secret    │  │ KV v2 Engine      │  │
│  │ Operator (VSO)  │─┼──────────────────────▶│  │ (demo-kv/)        │  │
│  └────────┬────────┘ │                       │  └───────────────────┘  │
│           │          │                       │                         │
│  ┌────────▼────────┐ │                       │  ┌───────────────────┐  │
│  │ K8s Secret      │ │                       │  │ JWT Auth Method   │  │
│  │ (synced secret) │ │                       │  │ + Policy + Role   │  │
│  └─────────────────┘ │                       │  └───────────────────┘  │
│                       │                       │                         │
└──────────────────────┘                       └─────────────────────────┘
```

## Prerequisites

- `01-deploy-eks` has been applied and the EKS cluster is running
- An HCP Vault Dedicated cluster exists and is accessible (public endpoint)
- A Vault admin token with permissions to enable auth methods, create policies, and manage secrets engines
- TFC workspace configured with access to `01-deploy-eks` outputs (`pcarey-org` org)

## Usage

```bash
terraform init
terraform plan
terraform apply
```

> **Note:** `vault_address` and `vault_token` are required variables with no defaults. Set them in TFC or via `-var` flags.

## Variables

| Variable | Type | Description | Default |
|---|---|---|---|
| `vault_address` | `string` | Full URL of the HCP Vault Dedicated cluster | — (required) |
| `vault_token` | `string` (sensitive) | Admin token for configuring the Vault cluster | — (required) |
| `vault_namespace` | `string` | Vault namespace | `"admin"` |
| `region` | `string` | AWS region (must match 01-deploy-eks) | `"ap-southeast-2"` |
| `tfc_org` | `string` | TFC organization name | `"pcarey-org"` |
| `tfc_workspace_eks` | `string` | TFC workspace name for 01-deploy-eks outputs | `"deploy-eks"` |
| `demo_secret_path` | `string` | KV v2 mount path | `"demo-kv"` |
| `demo_secret_name` | `string` | Secret name within KV v2 | `"demo-app/config"` |
| `demo_secret_data` | `map(string)` | Key-value pairs for the demo secret | `{ username = "demo-user", password = "sup3rS3cret!" }` |
| `kubernetes_namespace` | `string` | Namespace for the demo app and synced secret | `"demo-app"` |

## Outputs

| Output | Description |
|---|---|
| `vault_auth_method_path` | Path of the JWT auth method in Vault |
| `vault_policy_name` | Name of the Vault policy created |
| `kubernetes_namespace` | Namespace where the secret is synced |
| `synced_secret_name` | Name of the Kubernetes Secret created by VSO |
| `vso_helm_release_status` | Status of the VSO Helm release |

## Verification

After applying, verify the secret was synced to Kubernetes:

```bash
# Update kubeconfig
aws eks update-kubeconfig --region ap-southeast-2 --name <cluster-name>

# Check the synced secret exists
kubectl get secret demo-kv-secret -n demo-app

# View the secret data
kubectl get secret demo-kv-secret -n demo-app -o jsonpath='{.data}' | jq
```

## Key Design Decisions

- **JWT auth over Kubernetes auth**: HCP Vault Dedicated cannot reach the Kubernetes API server directly. JWT auth uses OIDC discovery (a public URL) to validate tokens.
- **Single workspace**: Keeps all related configuration together for simplicity.
- **EKS OIDC as JWT issuer**: Leverages the native EKS OIDC provider — no additional identity infrastructure needed.
