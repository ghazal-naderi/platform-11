# kops-seed
This Terraform module will create the most basic components required for a `kops` cluster.

When creating the cluster, ensure that you set `KOPS_STATE_STORE=${s3_bucket}` and use parameters `--state=s3://${s3_bucket} --out=. --target=terraform` with `${s3_bucket}` being the bucket creted by this module.

```
export KOPS_STATE_STORE=s3://fakebank-stage-state
export KOPS_DNS_ZONE=Z00979322Q0EUOGTXWWA2
kops create cluster fakebank-stage.enva.gen6bk.com \
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

If you are using an encrypted S3 bucket, like the one in `kops-seed`, you should make sure to add `additionalPolicies` sufficient to give nodes and masters the ability to pull their configurations from the bucket and therefore to decrypt the contents. The policy to do so is below and can be applied via `kops edit cluster ${CLUSTER_NAME}`. Be sure to change the `arn` values to your own for `arn:aws:kms`, `arn:aws:secretsmanager`, `arn:aws:autoscaling` and `arn:aws:r53`.

```
spec:
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
            "arn:aws:kms:us-east-1:850315125037:key/4b0966b8-c474-4d00-9d5d-d785e4e324d6"
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
            "Resource": "arn:aws:secretsmanager:*:850315125037:secret:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/Z00979322Q0EUOGTXWWA2"
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
            "Resource": [ "arn:aws:autoscaling:us-east-1:850315125037:autoScalingGroup:6c1fe66b-cf23-46a9-b285-db285d9cacf6:autoScalingGroupName/nodes.fakebank-stage.enva.gen6bk.com" ]
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
            "arn:aws:kms:us-east-1:850315125037:key/4b0966b8-c474-4d00-9d5d-d785e4e324d6"
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
            "Resource": "arn:aws:secretsmanager:*:850315125037:secret:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/*"
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
        }
      ]
```

There are a few extra commands to run when the cluster is up, since we're using coredns:
for (kops#6318)[https://github.com/kubernetes/kops/issues/6318]:
```
k delete deployment -n kube-system kube-dns-autoscaler
k delete deployment -n kube-system kube-dns
```
