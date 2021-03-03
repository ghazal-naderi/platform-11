# aws-vpn
## intro
aws-vpn is used to deploy a VPN for a private Kubernetes topology, as a single point of external access.

In order to use it with Google Apps, you must obtain SAML IdP metadata (eg. [from Google](https://benincosa.com/?p=3787)) and complete additional setup for each endpoint used.

## inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account | target account alias used in DNS - eg. `dev`, `prod` | `string` | n/a | yes |
| domain | target tld - eg. `fakebank.com` | `string` | n/a | yes |
| environment | target environment - eg `int`, `qa` | `string` | n/a | yes |
| saml\_provider\_arn | provider arn for saml integration | `any` | n/a | yes |

## example
for the cluster 
```
resource "aws_iam_saml_provider" "saml" {
  name = "Google"
  saml_metadata_document = file("${path.module}/idp-profile/saml.xml")
}

module "vpn_int" {
  source = "../structs/aws-vpn"
  domain = "fakebank.com"
  account = "dev"
  environment = "int"
  saml_provider_arn = aws_iam_saml_provider.saml.arn
}
```
