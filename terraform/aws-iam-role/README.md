##terraform-aws-iam-assumed-roles

Terraform module to provision  IAM roles and  IAM groups for assuming the roles provided MFA is present, and add IAM users to the groups. e.g

Role and group with Administrator (full) access to AWS resources
Role and group with Readonly access to AWS resources

To give a user administrator's access, add the user to the admin group.

To give a user readonly access, add the user to the readonly group.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_name | Name for the admin group and role (e.g. `admin`) | `string` | `"admin"` | no |
| admin\_user\_names | Optional list of IAM user names to add to the admin group | `list(any)` | `[]` | no |
| attributes | Additional attributes (e.g. `policy` or `role`) | `list(any)` | `[]` | no |
| backenddeveloper\_name | Name for the backenddeveloper group and role (e.g. `backenddeveloper`) | `string` | `"backenddeveloper"` | no |
| backenddeveloper\_user\_names | Optional list of IAM user names to add to the backenddeveloper group | `list(any)` | `[]` | no |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name`, and `attributes` | `string` | `"-"` | no |
| enabled | Set to false to prevent the module from creating any resources | `string` | `"true"` | no |
| frontenddeveloper\_name | Name for the frontenddeveloper group and role (e.g. `frontenddeveloper`) | `string` | `"frontenddeveloper"` | no |
| frontenddeveloper\_user\_names | Optional list of IAM user names to add to the frontenddeveloper group | `list(any)` | `[]` | no |
| leaddeveloper\_name | Name for the leaddeveloper group and role (e.g. `leaddeveloper`) | `string` | `"leaddeveloper"` | no |
| leaddeveloper\_user\_names | Optional list of IAM user names to add to the leaddeveloper group | `list(any)` | `[]` | no |
| namespace | Namespace (e.g. `ml` or `milli`) | `string` | n/a | yes |
| platform\_name | Name for the platform group and role (e.g. `platform`) | `string` | `"platform"` | no |
| platform\_user\_names | Optional list of IAM user names to add to the platform group | `list(any)` | `[]` | no |
| qualityassurance\_name | Name for the qualityassurance group and role (e.g. `qualityassurance`) | `string` | `"qualityassurance"` | no |
| qualityassurance\_user\_names | Optional list of IAM user names to add to the qualityassurance group | `list(any)` | `[]` | no |
| readonly\_name | Name for the readonly group and role (e.g. `readonly`) | `string` | `"readonly"` | no |
| readonly\_user\_names | Optional list of IAM user names to add to the readonly group | `list(any)` | `[]` | no |
| security\_name | Name for the admin group and role (e.g. `security`) | `string` | `"security"` | no |
| security\_user\_names | Optional list of IAM user names to add to the security group | `list(any)` | `[]` | no |
| developer\_name | Name for the developer group and role (e.g. `developer`) | `string` | `"developer"` | no |
| developer\_user\_names | Optional list of IAM user names to add to the developer group | `list(any)` | `[]` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | `string` | n/a | yes |
| switchrole\_url | URL to the IAM console to switch to a role | `string` | `"https://signin.aws.amazon.com/switchrole?account=%s&roleName=%s&displayName=%s"` | no |
| tags | Additional tags (e.g. map(`BusinessUnit`,`XYZ`) | `map(any)` | `{}` | no |

## Outputs

No output.


