# aws-aurora_erverless
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| auto\_pause | Whether or not the DB should pause on idle | `bool` | `false` | no |
| db\_subnet\_confs | Config objects to use for db subnets | `map` | n/a | yes |
| ingress\_cidr\_blocks | CIDR blocks that should be allowed to access the DB subnets | `list` | n/a | yes |
| master\_username | Master username for DB instance | `string` | `"postgresql"` | no |
| max\_capacity | Maximum ACU capacity. Must be a power of two up to max 256 | `number` | `16` | no |
| min\_capacity | Minimum ACU capacity. Must be a power of two up to max 256 | `number` | `2` | no |
| name | Instance name to be use for resource naming and tags | `string` | `"serverless_db"` | no |
| seconds\_until\_auto\_pause | Number of seconds with of idle connection acitivity before the DB will pause | `number` | `300` | no |
| vpc\_id | ID of the VPC within which the DB will be created | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| db\_id | The ID for the db |
| db\_name | The name for the db |
| endpoint | The endpoint for the db |
| master\_username | The master username for the db |
| reader\_endpoint | The read only endpoint for the db |
| temp\_password | The initial random temp password |

