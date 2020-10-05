# gcp-sql
## Introduction
This will automatically deploy a Google SQL high availability instance on GCP. 

## Requirements

Your Terraform serviceAccount must have the IAM roles:
- Service Networking Admin
- Cloud SQL Admin

## Providers

| Name | Version |
|------|---------|
| google | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| database\_tier | n/a | `string` | `"db-f1-micro"` | no |
| database\_version | n/a | `string` | `"POSTGRES_11"` | no |
| disk\_size | n/a | `string` | `"10"` | no |
| project | n/a | `any` | n/a | yes |

## Outputs

No output.

