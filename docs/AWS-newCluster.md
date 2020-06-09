# Creating a new AWS Cluster
## `infra` repository
1. If not done already, create a new `infra` Github repository on the client's Github accont
2. Populate the `infra` repository with the Github action from [client-repo-gather-deps](https://github.com/11FSConsulting/platform/tree/master/components/client-repo-gather-deps)
3. Setup the secrets `AWS_PLATFORM_ECR_ACCESS_KEY_ID`, `AWS_PLATFORM_ECR_SECRET_ACCESS_KEY` & `GH_BOT_SECRET_TOKEN` on the repository.
## Creating a Kubernetes cluster
1. Create the directory `k8s/{env}`, with `{env}` representing one of the agreed environment names (eg. `int`, `qa`, `production`)
2. Create the directory `terraform/{account}`, with `{account}` representing the AWS account name (eg. `dev`, `prod`)
3. Add `aws-kops-seed` to `manifest.yaml` from the repository creation step, like:
```
packages:
   - name: terraform/aws-kops-seed
     path: terraform/structs/aws-kops-seed
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
```
4. Set necessary AWS variables (`AWS_REGION`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`) and use a combination of the `aws-kops-seed` struct and additional DNS entries to prepare the AWS account by creating and applying a `main.tf` in `terraform/{account}/seed`:
```
provider "aws" {}

module "kops-seed" {
  source = "../../structs/aws-kops-seed"
  environment = "dev"
  project = "fakebank"
  region = "us-east-1"
  zone_name = "us-east-1.dev.fakebank.com"
}

data "aws_route53_zone" "regional_zone" {
  name = "us-east-1.dev.fakebank.com"
}

resource "aws_route53_zone" "int_useast1" {
  name = "int.us-east-1.dev.fakebank.com"
}

resource "aws_route53_record" "int_useast1_record" {
  allow_overwrite = true
  name            = "int"
  ttl             = 30
  type            = "NS"
  zone_id         = data.aws_route53_zone.regional_zone.zone_id

  records = [
    aws_route53_zone.int_useast1.name_servers.0,
    aws_route53_zone.int_useast1.name_servers.1,
    aws_route53_zone.int_useast1.name_servers.2,
    aws_route53_zone.int_useast1.name_servers.3,
  ]
}

resource "aws_route53_zone" "qa_useast1" {
  name = "qa.us-east-1.dev.fakebank.com"
}

resource "aws_route53_record" "qa_useast1_record" {
  allow_overwrite = true
  name            = "qa"
  ttl             = 30
  type            = "NS"
  zone_id         = data.aws_route53_zone.regional_zone.zone_id

  records = [
    aws_route53_zone.qa_useast1.name_servers.0,
    aws_route53_zone.qa_useast1.name_servers.1,
    aws_route53_zone.qa_useast1.name_servers.2,
    aws_route53_zone.qa_useast1.name_servers.3,
  ]
}
```

In this example, we've initialized DNS names for two environments:
- `int.us-east-1.dev.fakebank.com` for an `int` environment in `us-east-1` for account `dev`
- `qa.us-east-1.dev.fakebank.com` for a `qa` environment in `us-east-1` for account `dev`

This seed initializes the environment with basic configuration and the seed module outputs the AWS keys necessary for subequent steps.
5. Re-set your AWS keys (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) with the keys from the previous step. Export the variable `KOPS_STATE_STORE` with the S3 bucket created by the aforementioned module and `KOPS_DNS_ZONE` with the zone ID of the first environment to be created (eg `int.eu-west-1.dev.fakebank.com`), created by the `main.tf` code above.
6. Install `kops` (`brew install kops`) and use it to initialize the cluster on the S3 bucket using the DNS zone exported in the last step.
```
kops create cluster int.us-east-1.dev.fakebank.com \
    --state "${KOPS_STATE_STORE}" \
    --zones "us-east-1a,us-east-1b,us-east-1c" \
    --master-zones "us-east-1a,us-east-1b,us-east-1c" \
    --networking cilium \
    --topology private \
    --bastion \
    --dns public \
    --dns-zone "${KOPS_DNS_ZONE}" \
    --node-count 3 \
    --node-size t3a.medium \
    --kubernetes-version 1.15.10 \
    --master-size t3a.medium 
```
The above example command will create a 3-master, 3-node Kubernetes cluster.
7. Make the edits (with `kops edit cluster int.us-east-1.dev.fakebank.com`) outlined in the `aws-kops-seed` `README.md` available [here](https://github.com/11FSConsulting/platform/tree/master/terraform/aws-kops-seed). This will enable `coredns`, provide access to the encrypted S3 bucket for nodes and enable metrics monitoring.
8. Use `kops update cluster int.us-east-1.dev.fakebank.com --yes` - if anything isn't working, review step 7 and make the necessary changes.
9. Reduce the number of `bastion` hosts to `0` for the cluster as they are not necessary to run 24/7 and are only needed for SSH access. Check that the cluster validates:
```
kops edit ig bastions
kops validate cluster
```
10. Add the rest of the suggested structs to `manifests.yaml` in the `infra` repo in order to enrich the cluster with 11:FS pre-packaged goodies:
```
packages:
   - name: k8s/auth
     path: k8s/base/structs/auth
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/aws-cluster-autoscaler
     path: k8s/base/structs/aws-cluster-autoscaler
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/cert-manager
     path: k8s/base/structs/cert-manager
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa 
   - name: k8s/descheduler
     path: k8s/base/structs/descheduler
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/eck-exporter
     path: k8s/base/structs/eck-exporter
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/eck
     path: k8s/base/structs/eck
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/external-dns
     path: k8s/base/structs/external-dns
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa   
   - name: k8s/external-secrets
     path: k8s/base/structs/external-secrets
     ref: 4848fa01956b0cb75ad83f8282afde6777dc4dac 
   - name: k8s/fluentd
     path: k8s/base/structs/fluentd
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/ingress-nginx
     path: k8s/base/structs/ingress-nginx
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/jaeger
     path: k8s/base/structs/jaeger
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/kafka
     path: k8s/base/structs/kafka
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/tekton-pipelines
     path: k8s/base/structs/tekton-pipelines
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/postgres-operator
     path: k8s/base/structs/postgres-operator
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/prometheus
     path: k8s/base/structs/prometheus
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa
   - name: k8s/reloader
     path: k8s/base/structs/reloader
     ref: f40ae9c71cacacd747a770a207582451ea1c4bfa 
 ```
This example includes almost every struct, remove the ones that are not required.

For a base installation:
- `tekton-pipelines` provides CD for the environment and links up to Github
- `reloader` will automatically refresh pods that depend on secrets via annotations
- `prometheus` will automatically monitor the cluster
- `postgres-operator` will provide CRDs to manage postgres users and databases
- `kafka` will provide an HA Kafka cluster
- `jaeger` will provide distributed tracing capabilities
- `ingress-nginx` will provide the means to automatically manage ingresses
- `external-dns` wil expose those ingresses under the cluster's subdomain
- `fluentd` will provide logging for nodes
- `eck` will provide an elasticsearch cluster to host logs
- `eck-exporter` will provide monitoring for `eck` via `prometheus`
- `descheduler` will attempt to keep nodes balanced in resource usage
- `cert-manager` will manage and auto-generate certificates via letsencrypt
- `external-secrets` will interface with Vault or AWS Secrets Manager to manage secret values
- `auth` will ensure properly annotated `ingress` resources are authenticated via Github org membership
- `aws-cluster-autoscaler` will manage the ASG for nodes and attempt to automatically and smartly scale 

11. (TODO: Document this) Use a current project in order to ascertain what customizations are needed over these structs. Most of them have a `README.md` with extra required configuration.

