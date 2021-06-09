# terraform-aws-waf-owasp-top-10-rules


## Description

OWASP Top 10 Most Critical Web Application Security Risks is a powerful awareness document for web application security. It represents a broad consensus about the most critical security risks to web applications.

This is a Terraform module which creates AWF WAF resources for protection of your resources from the OWASP Top 10 Security Risks. This module is based on the whitepaper that AWS provides. The whitepaper tells how to use AWS WAF to mitigate those attacks[[1]](https://d0.awsstatic.com/whitepapers/Security/aws-waf-owasp.pdf)[[2]](https://aws.amazon.com/about-aws/whats-new/2017/07/use-aws-waf-to-mitigate-owasps-top-10-web-application-vulnerabilities/).

This module will only create match-sets[[4]](https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-create-condition.html), rules[[4]](https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-rules.html), and a rule group (optional)[[5]](https://docs.aws.amazon.com/waf/latest/developerguide/working-with-rule-groups.html).
Those resources cannot be used without WebACL[[6]](https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-working-with.html), which is not covered by this module.

References
* [1] : https://d0.awsstatic.com/whitepapers/Security/aws-waf-owasp.pdf
* [2] : https://aws.amazon.com/about-aws/whats-new/2017/07/use-aws-waf-to-mitigate-owasps-top-10-web-application-vulnerabilities/
* [3] : https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-create-condition.html
* [4] : https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-rules.html
* [5] : https://docs.aws.amazon.com/waf/latest/developerguide/working-with-rule-groups.html
* [6] : https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-working-with.html

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
| create\_rule\_group | All rules can be grouped into a Rule Group. Unfortunately, AWS WAF Rule Group limit per region is only 3. By setting the value to `false` will not create the rule group. Default to `true`. | `string` | `"true"` | no |
| csrf\_expected\_header | The custom HTTP request header, where the CSRF token value is expected to be encountered | `string` | `"x-csrf-token"` | no |
| csrf\_expected\_size | The size in bytes of the CSRF token value. For example if it's a canonically formatted UUIDv4 value the expected size would be 36 bytes/ASCII characters. | `string` | `"36"` | no |
| description | The description of these resources. | `string` | n/a | yes |
| environment | The environment of these resources belong to. | `string` | n/a | yes |
| max\_expected\_body\_size | Maximum number of bytes allowed in the body of the request. If you do not plan to allow large uploads, set it to the largest payload value that makes sense for your web application. Accepting unnecessarily large values can cause performance issues, if large payloads are used as an attack vector against your web application. | `string` | `"4096"` | no |
| max\_expected\_cookie\_size | Maximum number of bytes allowed in the cookie header. The maximum size should be less than 4096, the size is determined by the amount of information your web application stores in cookies. If you only pass a session token via cookies, set the size to no larger than the serialized size of the session token and cookie metadata. | `string` | `"4093"` | no |
| max\_expected\_query\_string\_size | Maximum number of bytes allowed in the query string component of the HTTP request. Normally the  of query string parameters following the ? in a URL is much larger than the URI , but still bounded by the  of the parameters your web application uses and their values. | `string` | `"1024"` | no |
| max\_expected\_uri\_size | Maximum number of bytes allowed in the URI component of the HTTP request. Generally the maximum possible value is determined by the server operating system (maps to file system paths), the web server software, or other middleware components. Choose a value that accomodates the largest URI segment you use in practice in your web application. | `string` | `"512"` | no |
| product\_domain | The name of the product domain these resources belong to. | `string` | n/a | yes |
| service\_name | The name of the service these resources belong to. | `string` | n/a | yes |
| target\_scope | Valid values are `global` and `regional`. If `global`, means resources created will be for global targets such as Amazon CloudFront distribution. For regional targets like ALBs and API Gateway stages, set to `regional` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| rule01\_sql\_injection\_rule\_id | AWS WAF Rule which mitigates SQL Injection Attacks. |
| rule02\_auth\_token\_rule\_id | AWS WAF Rule which blacklists bad/hijacked JWT tokens or session IDs. |
| rule03\_xss\_rule\_id | AWS WAF Rule which mitigates Cross Site Scripting Attacks. |
| rule04\_paths\_rule\_id | AWS WAF Rule which mitigates Path Traversal, LFI, RFI. |
| rule06\_php\_insecure\_rule\_id | AWS WAF Rule which mitigates PHP Specific Security Misconfigurations. |
| rule07\_size\_restriction\_rule\_id | AWS WAF Rule which mitigates abnormal requests via size restrictions. |
| rule08\_csrf\_rule\_id | AWS WAF Rule which enforces the presence of CSRF token in request header. |
| rule09\_server\_side\_include\_rule\_id | AWS WAF Rule which blocks request patterns for webroot objects that shouldn't be directly accessible. |
| rule\_group\_id | AWS WAF Rule Group which contains all rules for OWASP Top 10 protection. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Contributing

This module accepting or open for any contributions from anyone, please see the [CONTRIBUTING.md](https://github.com/traveloka/terraform-aws-elasticache-memcached/blob/master/CONTRIBUTING.md) for more detail about how to contribute to this module.

## License

This module is under Apache License 2.0 - see the [LICENSE](https://github.com/traveloka/terraform-aws-elasticache-memcached/blob/master/LICENSE) file for details.https://github.com/siahaanbernard)
 
