# Creating a new AWS Cluster
## `infra` repository
1. Copy a new `infra` repository from the [11FSConsulting/infra](https://github.com/11FSConsulting/infra) template into the client's Github account.

2. Create a Github bot user for your project and assign it to a `Bots` group with `admin` access for the `infra` repository and `read` to any application repositories. Create a personal access token with the following permissions:
- `repo`
- `read:org`
- `read:public_key`
- `admin:repo_hook`
- `user:email`

Save the PAT with a nice name. This will be used for automation.

3. Setup the secrets `AWS_PLATFORM_ECR_ACCESS_KEY_ID`, `AWS_PLATFORM_ECR_SECRET_ACCESS_KEY` & `GH_BOT_SECRET_TOKEN` on the repository. `GH_BOT_SECRET_TOKEN` is your aforementioned bot's PAT and the AWS keys must have ECR image pull permissions on `platform/infra-tester` built via [11FSConsulting/platform](https://github.com/11FSConsulting/platform/blob/master/.github/workflows/build_image.yml).

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
# In this example, we are creating:
# - a regional DNS zone for the environment dev.fakebank.com for us-east-1
# - two environments under that DNS zone, qa and int
# For a single cluster, single zone installation the `kops-seed` module alone should suffice

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

This seed initializes the environment with basic configuration and the seed module outputs the AWS keys necessary for subequent steps. Use `terraform show -json | jq` to retrieve secret values. It's good practice here to add them to a shared 1Password secret under `AWS {environment} Kops` with `AWS_ACCESS_KEY_ID` as `username`, `AWS_SECRET_ACCESS_KEY` as `password` and custom `S3 Bucket`, `Region` and `DNS Zone ID` labels to make it easy to administer the `Kops` cluster at short notice.

5. Re-set your AWS keys (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) with the keys from the previous step. Export the variable `KOPS_STATE_STORE` with the S3 bucket (eg `s3://$bucketname`) created by the aforementioned module and `KOPS_DNS_ZONE` with the zone ID of the first environment to be created (eg. `Z0220055AWXE17E24EY` for `int.eu-west-1.dev.fakebank.com`) created by the `main.tf` code above.

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
10. Identify the necessary structs. The `sandbox` includes almost every struct, remove the ones that are not required from `manifest.yaml`, `k8s/base/structs` and `k8s/base/kustomization.yaml`. Make a copy of `k8s/sandbox` called `k8s/${env}` with `${env}` being your environment name (eg. `int`).

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

11. Use `sed` to replace all mention of the default domain name with your own. Example:
```
brew install gnu-tools
cd k8s/${env}
gsed -i *.yaml -e 's/int.us-east-1.dev.gen6bk.com/sandbox.11fs-structs.com/g'
```

12. For `auth`, create an oAuth application as the client account bot for the `auth` struct. Use the following details, making changes to the URL (`int.us-east-1.dev.fakebank.com`) and name (`FakeBank`) as necessary.
- Homepage URL: `http://auth.int.us-east-1.dev.fakebank.com`
- Authorization Callback URL: `https://auth.int.us-east-1.dev.fakebank.com/oauth2/callback`
- Application Name: `FakeBank Authentication (Int)`

Use the returned `Client ID` and `Client Secret`, base64 encode them via `echo -ne "${value}" | base64` and replace the values in `k8s/${env}/auth-custom.yaml`. In the same file, replace the values for `github_org`, `cookie_domain` and `whitelist_domains` with the client github organization and cluster domain as above (eg. `fakebank` and `.int.us-east-1.dev.fakebank.com`). 

13. For `tekton`, we need to:
- Update `default` for `kustomizeDir` `param` in `tekton-pipeline.yaml` to represent the environment directory, eg. `k8s/int`
- Create 2 secrets in AWS Secrets Manager:
  - `git-ssh-key`: property `ssh-privatekey` is an RSA encoded private key allocated to the aforementioned bot user. Generate one with `ssh-keygen -f bot_id_rsa` and add it to the bot's keys then use the output of `cat bot_id_rsa`.
  - `git-webhook`: property `username` is the name of the bot user and property `access-token` is the personal access token generated above for the bot.
- Update the `TriggerTemplate` in `tekton-triggers.yaml` to change the `resourceSpec` `url` `param` to point to the appropriate Github `infra` repository, eg. `https://github.com/FakeBank/infra.git`
- Update the `GitHubOrg` and `GitHubUser` in the `TaskRun` in `tekton-triggers.yaml` to point to the appropriate Github `infra` repository and bot user, eg. `FakeBank` and `fakebank-cicd` respectively.
  
14. For AWS Cluster Autoscaler, we need to replace `nodes=` in `aws-cluster-autoscaler.yaml` with the ASG name and desired min/max number of nodes. For minimum 3, maximum 6 nodes, for example, use `3:6:nodes.int.us-east-1.dev.fakebank.com`.

15. For Prometheus, create an app at https://api.slack.com/apps. Scope it to your client's Slack namespace and activate incoming webhooks. Create a webhook then `base64` decode the contents of the `alert-manager-main` secret from `prometheus-custom.yaml` and replace the `slack_api_url` with your webhook. Also be sure to replace the alert `title` in `slack_configs` to be more meaningful for your environment. Also decode `grafana.ini` from the `grafana-config` `Secret`, replace `root_url` with `grafana.int.us-east-1.dev.fakebank.com` for example and re-encode it into the secret.

At this point, use `kustomize` to verify that the configuration is being correctly rendered:

```
kustomize build .
```

If so, commit and push all changes to `master` on your `infra` repo, make sure you are in the correct context and apply the configuration! From then on, your cluster will automatically keep itself up to date with your `infra` git repository.

```
git add -A
git commit -m 'Make changes necessary for fakebank int cluster'
git push --set-upstream origin feature/new-environment
k config use-context int.us-east-1.dev.fakebank.com
kustomize build . | k apply -f -
```
