# Monitoring CloudTrail Log Files with Amazon CloudWatch Logs

# aws-cloudtrail
This module creates an S3 bucket and associated CloudTrail rule for audit logs. The bucket is encrypted with SSE via an automatically generated KMS key with a deletion window of 30 days. 
The bucket logging is enabled and depends on bucket which has been created from aws-s3-logs module. 

# aws-cloudwatch
This module creates alarms for tracking important changes and occurances from cloudtrail. 

The module creates following filters to send notification to the sns topics :

          * IAM Policy Changes
         
          * Security Group Configuration Changes
             
          * Console Signin Failures
         
          * Network Access Control List Changes


## Providers

The following providers are used by this module:

| Name | Version |
| ---- | ------- |
| `aws`  |         |

## Required Inputs

The implementor should provide the same variables as used in aws-s3-logs module for environment and project.

| Name | Default | Description | Type |
| ---- | ------- | ----------- | ------- |
| `project` | `my` | This is used to name the S3 bucket used to deliver audit logs and will be the same variable as used in aws-s3-logs module | `string` |
| `environment` |`dev`    |This will be the same variable as used in aws-s3-logs module | `string` |


## Outputs

| Name | Description |
| ---- | ------- |
| sns_topic_arn  | The ARN of the SNS topic used        |

