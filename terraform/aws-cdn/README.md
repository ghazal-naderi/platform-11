# aws-cdn
## Description

Creates an S3 bucket fronted by a CloudFront CDN and Route53 record with associated AWS certificate for asset storage.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket | n/a | `string` | `"assets.int"` | no |
| environment | n/a | `string` | `"int"` | no |
| subdomain | n/a | `string` | `"assets"` | no |
| zone | n/a | `string` | `"dev.fakebank.com"` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket\_id | n/a |

