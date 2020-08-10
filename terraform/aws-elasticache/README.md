# aws-elasticache
This creates an AWS ElastiCache cluster

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cache\_subnet\_confs | Config objects to use for cache subnets | `map` | n/a | yes |
| ingress\_cidr\_blocks | CIDR blocks that should be allowed to access the cache subnets | `list` | n/a | yes |
| name | Instance name to be use for resource naming and tags | `string` | `"cache"` | no |
| node\_type | The type or size of the ElastiCache node(s) | `string` | `"cache.t3.medium"` | no |
| shards | The number of shards to be used for ElastiCache | `string` | `"1"` | no |
| vpc\_id | ID of the VPC within which the cache will be created | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| configuration\_endpoint | The endpoint for the ElastiCache cluster for host discovery |
| elasticache\_id | The ID for the cluster |
| primary\_endpoint | The endpoint for the ElastiCache cluster for primary data access |

