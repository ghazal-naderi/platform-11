# aws-s3-logs
This module creates an S3 bucket for log output from environments. The bucket is encrypted with SSE via an automatically generated KMS key with a deletion window of 30 days.

## Inputs
| Name | Default | Description |
| ---- | ------- | ----------- |
| `project` | `my` | This is used to name the S3 bucket used to deliver logs |
| `environment` | `dev` | This is used to determine the name of the S3 bucket |

## Usage
This is to be paired with the `logging-operator` `k8s` struct. It can be used to instantiate an S3 bucket and, after adding the appropriate node policies, used as a destination for all logs for long-term storage. 
```
    {
      "Effect": "Allow",
      "Action": [
        "kms:CreateGrant",
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ],
      "Resource": [
        "arn:aws:kms:::key/xxxxxx-xxxx-xxx-xxxx-xxxxx"
      ]
    },
    {
      "Sid": "DownloadandUpload",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::awsexamplebucket/*"
    },
    {
      "Sid": "ListBucket",
      "Action": [
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::awsexamplebucket"
    },
```

It also comes preconfigured for `ingress-nginx` to be configured to send ELB access logs under the prefix `logs`.
