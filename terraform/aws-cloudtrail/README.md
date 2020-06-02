# aws-cloudtrail
This module creates an S3 bucket and associated CloudTrail rule for audit logs. The bucket is encrypted with SSE via an automatically generated KMS key with a deletion window of 30 days.

## Inputs
| Name | Default | Description |
| ---- | ------- | ----------- |
| `project` | `my` | This is used to name the S3 bucket used to deliver audit logs |
