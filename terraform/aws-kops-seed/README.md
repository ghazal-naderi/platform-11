# kops-seed
This Terraform module will create the most basic components required for a `kops` cluster.

When creating the cluster, ensure that you set `KOPS_STATE_STORE=${s3_bucket}` and use parameters `--state=s3://${s3_bucket} --out=. --target=terraform` with `${s3_bucket}` being the bucket creted by this module.

```
export KOPS_STATE_STORE=s3://fakebank-stage-state
export KOPS_DNS_ZONE=Z00979322Q0EUOGTXWWA2
kops create cluster fakebank.stage.env.fake.com \
    --state "${KOPS_STATE_STORE}" \
    --zones "us-east-1a,us-east-1b,us-east-1c" \
    --master-zones "us-east-1a,us-east-1b,us-east-1c" \
    --networking cilium \
    --topology private \
    --bastion \
    --dns public \
    --dns-zone "${KOPS_DNS_ZONE}" \
    --node-count 4 \
    --node-size r5.large \
    --kubernetes-version 1.15.10 \
    --master-size r5.large 
```

For DNS, we should edit with `kops edit cluster` in order to add:

```
spec:
  kubeDNS:
    provider: CoreDNS
```
For metrics monitoring, we should edit in order to add:
```
kubelet:
    authenticationTokenWebhook: true
    authorizationMode: Webhook
```

If you are using an encrypted S3 bucket, like the one in `kops-seed`, you should make sure to add `additionalPolicies` sufficient to give nodes and masters the ability to pull their configurations from the bucket and therefore to decrypt the contents. The policy to do so is below and can be applied via `kops edit cluster ${CLUSTER_NAME}`. Be sure to refer to the notes below on how to change the ARN values for your own infrastructure.

```
  additionalPolicies:
    master: |
      [
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
            "<< SEE NOTE #1 BELOW >>"
          ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": "<< SEE NOTE #2 BELOW >>"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "<< SEE NOTE #3 BELOW >>"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags"
            ],
            "Resource": [ "*" ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": [ "<< SEE NOTE #4 BELOW >>" ]
        }
      ]
    node: |
      [
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
            "<< SEE NOTE #1 BELOW >>"
          ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecretVersionIds"
            ],
            "Resource": "<< SEE NOTE #2 BELOW >>"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets"
            ],
            "Resource": [
                "*"
            ]
        }
      ]
```

Notes:
1. This is the KMS key used to encrypt/decrypt objects in your kops S3 bucket, to retrieve it from the Terraform `aws-kops-seed` state use the command `terraform show -json | jq -r '.values.root_module.child_modules|.[].resources|.[]|select(.address=="aws_kms_key.bucketenckey")|.values.arn'`
2. This is the AWS SecretsManager ARN used to permit access to external secrets via AWSSM. To allow access to all secrets, use `arn:aws:secretsmanager:::secret:*` - be aware this will permit access to all AWS secrets across the account and other connected accounts. It is suggested to use something more granular such as a secret prefix here that is specific to a single environment.
3. This is the AWS Route53 zone ID under which records will be created. Use the command `terraform show -json | jq -r '.values.root_module.child_modules|.[].resources|.[]|select(.address=="aws_route53_zone.zone")|.values.zone_id'` to extract this from Terraform `aws-kops-seed` state. 
4. This is the autoscaling group that the master instances are able to control to scale-up and scale-down the cluster. It should refer to the nodes ASG ARN - use `arn:aws:autoscaling:::autoScalingGroup::autoScalingGroupName/nodes.fakebank.stage.env.fake.com` replacing `fakebank.stage.env.fake.com` with the FQDN of the zone used in step 3. 

There are a few extra commands to run when the cluster is up, since we're using coredns:
for (kops#6318)[https://github.com/kubernetes/kops/issues/6318]:
```
k delete deployment -n kube-system kube-dns-autoscaler
k delete deployment -n kube-system kube-dns
```
