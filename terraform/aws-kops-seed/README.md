# aws-kops-seed
This Terraform module will create the most basic components required for a `kops` cluster.

Kops version: `v1.19.0-beta.1`

When creating the cluster, ensure that you set `KOPS_STATE_STORE=${s3_bucket}` with `${s3_bucket}` being the bucket creted by this module.

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
    --dns private \
    --dns-zone "${KOPS_DNS_ZONE}" \
    --node-count 3 \
    --node-size m5a.large \
    --kubernetes-version 1.18.12 \
    --master-size t3a.large
```

For Encryption, we should edit with `kops edit cluster` and add `encryptedVolume: true` to each `etcd` volume.
Additionally, we should edit each instancegroup with `kops edit ig` and add `rootVolumeEncryption: true` to each instancegroup.
Be sure to set `image` in each instancegroup to at least `ubuntu/ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20201112.1`
For DNS, we should edit with `kops edit cluster` in order to add:

```
spec:
  kubeDNS:
    provider: CoreDNS
```
For making the API endpoint private (we suggest using a VPN for access as found in `aws-vpn` terraform struct), use:
```
  api:
    loadBalancer:
      class: Classic
      type: Internal
```
Note that if the ELB already exists we should delete it before applying the new configuration.

For autoscaling, we should add:
```
clusterAutoscaler:
  enabled: true
  skipNodesWithLocalStorage: true
  skipNodesWithSystemPods: true
```
For networking observability, we should add (requires latest `kops`):
```
  networking:
    cilium:
      hubble:
        enabled: true
        metrics:
        - dns
        - drop
        - flow
        - http
        - icmp
        - port-distribution
        - tcp
      preallocateBPFMaps: true
      version: v1.8.8
      enablePrometheusMetrics: true
```
For metrics monitoring, we should edit in order to add:
```
kubelet:
    authenticationTokenWebhook: true
    authorizationMode: Webhook
kubeControllerManager:
  authorizationAlwaysAllowPaths: 
  - /metrics
  - /healthz
kubeScheduler:
  authorizationAlwaysAllowPaths: 
  - /metrics
  - /healthz
```
For RBAC and Istio, we should add:
```
  authorization:
    rbac: {}
  kubeAPIServer:
    anonymousAuth: false
    apiAudiences:
    - api
    - istio-ca
    authorizationMode: RBAC
    serviceAccountIssuer: kubernetes.default.svc
    serviceAccountKeyFile:
    - /srv/kubernetes/service-account.key
    serviceAccountSigningKeyFile: /srv/kubernetes/service-account.key
    oidcClientID: dex-k8s-authenticator
    oidcGroupsClaim: groups
    oidcIssuerURL: https://dex.<cluster url>
    oidcUsernameClaim: email
```
For easier debugging, we should add:
```
kubelet:
  featureGates:
    EphemeralContainers: "true"
kubeAPIServer:
  featureGates:
    EphemeralContainers: "true"
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
                "arn:aws:route53:::hostedzone/<< SEE NOTE #3 BELOW >>",
                "arn:aws:route53:::hostedzone/<< SEE NOTE #3 BELOW >>"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:GetChange"
            ],
            "Resource": [
                "arn:aws:route53:::change/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets",
                "route53:ListHostedZonesByName"
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
            "Resource": [
                "arn:aws:route53:::hostedzone/<< SEE NOTE #3 BELOW >>",
                "arn:aws:route53:::hostedzone/<< SEE NOTE #3 BELOW >>"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:GetChange"
            ],
            "Resource": [
                "arn:aws:route53:::change/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets",
                "route53:ListHostedZonesByName"
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
3. This is the AWS Route53 zone ID under which records will be created. Each permission should allow access to each of the private and public zones. eg. use the command `terraform show -json | jq -r '.values.root_module.child_modules|.[].resources|.[]|select(.address=="aws_route53_zone.zone")|.values.zone_id'` to extract the public zone from Terraform `aws-kops-seed` state, change to `aws_route53_zone.private_zone` for private. 
4. This is the autoscaling group that the master instances are able to control to scale-up and scale-down the cluster. It should refer to the nodes ASG ARN - use `arn:aws:autoscaling:::autoScalingGroup::autoScalingGroupName/nodes.fakebank.stage.env.fake.com` replacing `fakebank.stage.env.fake.com` with the FQDN of the zone used in step 3. 

At this point, it's worth adding any other policies required - eg. if you're using the `logging-operator` struct and want to send logs to S3, you should add the policies outlined [here](https://github.com/11FSConsulting/platform/tree/master/terraform/aws-s3-logs).

There are a few extra commands to run when the cluster is up since we're using coredns. This only applies to versions of kops affected by [kops#6318](https://github.com/kubernetes/kops/issues/6318):
```
k delete deployment -n kube-system kube-dns-autoscaler
k delete deployment -n kube-system kube-dns
```
