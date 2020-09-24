# Creating a new GCP Cluster
## `infra` repository
1. Copy a new `infra` repository from the [11FSConsulting/infra](https://github.com/11FSConsulting/infra) template into the client's Github account.

2. Create a Github bot user for your project and assign it to a `Bots` group with `admin` access for the `infra` repository and `read` to any application repositories. Create a personal access token with the following permissions:
- `repo`
- `read:org`
- `read:public_key`
- `admin:repo_hook`
- `user:email`

Save the PAT with a nice name. This will be used for automation - remember to add it to 1Password.

3. Setup the secrets `GCLOUD_KEY` (base64 encoded serviceAccount json) & `GH_BOT_SECRET_TOKEN` on the repository. `GH_BOT_SECRET_TOKEN` is your aforementioned bot's PAT and the GCloud keys must have GCR image pull permissions on `platform/infra-tester` built via [11FSConsulting/platform](https://github.com/11FSConsulting/platform/blob/master/.github/workflows/build_image_gcp.yml). The struct `gcp-kops-seed` generates this account automatically, simply download the JSON key, encode it as Base64 and add it as the secret.

## Creating a Kubernetes cluster
1. Create the directory `k8s/{env}`, with `{env}` representing one of the agreed environment names (eg. `int`, `qa`, `production`)

2. Create the directory `terraform/{account}`, with `{account}` representing the Google account name (eg. `dev`, `prod`)

3. Add `gcp-kops-seed` to `manifest.yaml` from the repository creation step, like:
```
packages:
   - name: terraform/gcp-kops-seed
     path: terraform/structs/gcp-kops-seed
     ref: master 
```

4. Set necessary GCP variables (`GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_REGION` and `GOOGLE_ZONE`) and use the `gcp-kops-seed` struct by creating and applying a `main.tf` in `terraform/{account}/seed`:
```
provider "google" {}

module "kops-seed" {
  source = "../../structs/gcp-kops-seed"
  region = "us-central1"
  environment = "dev"
  project = "fakebank"
  domain = "int.us-central1.fakebank.com"
}
```

In this example, we've initialized DNS, GCR, GCS and service accounts for the environment `int.us-central1.fakebank.com`. 

5. Install `kops` (`brew install kops`)

6. Using `kops`, initialize the cluster on the GCS bucket using the DNS zone set in step 4. Use the commands and make the edits (with `kops edit cluster int.us-central1.fakebank.com`) outlined in the `gcp-kops-seed` `README.md` available [here](https://github.com/11FSConsulting/platform/tree/master/terraform/gcp-kops-seed). This will enable `coredns`, provide access to the encrypted S3 bucket for nodes and enable metrics monitoring.

7. Identify the necessary structs. The `sandbox` includes almost every struct, remove the ones that are not required from `manifest.yaml`, `k8s/base/structs` and `k8s/base/kustomization.yaml`. Make a copy of `k8s/sandbox` called `k8s/${env}` with `${env}` being your environment name (eg. `int`).

For a base installation:
- `tekton-pipelines` or `tekton-prod` provide CD for the environment and links up to Github
- `reloader` will automatically refresh pods that depend on secrets via annotations
- `prometheus` will automatically monitor the cluster
- `postgres-operator` will provide CRDs to manage postgres users and databases
- `kafka` will provide an HA Kafka cluster
- `jaeger` will provide distributed tracing capabilities
- `eck` will provide an elasticsearch cluster to store `jaeger` traces
- `dex-k8s-auth` will provide a basic frontend for obtaining rbac tokens
- `dex-rbac` will provide the backend to integrate k8s RBAC with Github/LDAP
- `eck-exporter` will provide monitoring for `eck` via `prometheus`
- `ingress-nginx` will provide the means to automatically manage ingresses
- `external-dns` wil expose those ingresses under the cluster's subdomain
- `logging-operator` will provide logging for nodes
- `loki` will provide log aggregation and and browsing capabilities via grafana installed by `prometheus`
- `descheduler` will attempt to keep nodes balanced in resource usage
- `cert-manager` will manage and auto-generate certificates via letsencrypt
- `external-secrets` will interface with Vault or Google Secrets Manager to manage secret values
- `auth` will ensure properly annotated `ingress` resources are authenticated via Github org membership
- `hubble-ui` will provide network observability if you use `cilium` as your CNI (as the default)

8. Use `sed` to replace all mention of the default domain name with your own. Example:
```
brew install gnu-tools
cd k8s/${env}
gsed -i *.yaml -e 's/int.us-east-1.dev.gen6bk.com/sandbox.11fs-structs.com/g'
```

9. For `auth`, create an oAuth application as the client account bot for the `auth` struct. Use the following details, making changes to the URL (`int.us-east-1.dev.fakebank.com`) and name (`FakeBank`) as necessary.
- Homepage URL: `http://auth.int.us-east-1.dev.fakebank.com`
- Authorization Callback URL: `https://auth.int.us-east-1.dev.fakebank.com/oauth2/callback`
- Application Name: `FakeBank Authentication (Int)`

Use the returned `Client ID` and `Client Secret`, base64 encode them via `echo -ne "${value}" | base64` and replace the values in `k8s/${env}/auth-custom.yaml`. In the same file, replace the values for `github_org`, `cookie_domain` and `whitelist_domains` with the client github organization and cluster domain as above (eg. `fakebank` and `.int.us-east-1.dev.fakebank.com`). 

10. For `tekton`, we need to:
- Update `default` for `kustomizeDir` `param` in `tekton-pipeline.yaml` to represent the environment directory, eg. `k8s/int`
- Create 2 secrets in Google Secrets Manager:
  - `git-ssh-key`: property `ssh-privatekey` is an RSA encoded private key allocated to the aforementioned bot user. Generate one with `ssh-keygen -f bot_id_rsa` and add it to the bot's keys then use the output of `cat bot_id_rsa`.
  - `git-webhook`: property `username` is the name of the bot user and property `access-token` is the personal access token generated above for the bot.
- Update the `TriggerTemplate` in `tekton-triggers.yaml` to change the `resourceSpec` `url` `param` to point to the appropriate Github `infra` repository, eg. `https://github.com/FakeBank/infra.git`
- Update the `GitHubOrg` and `GitHubUser` in the `TaskRun` in `tekton-triggers.yaml` to point to the appropriate Github `infra` repository and bot user, eg. `FakeBank` and `fakebank-cicd` respectively.
  
11. For Prometheus, create an app at https://api.slack.com/apps. Scope it to your client's Slack namespace and activate incoming webhooks. Create a webhook then `base64` decode the contents of the `alert-manager-main` secret from `prometheus-custom.yaml` and replace the `slack_api_url` with your webhook. Also be sure to replace the alert `title` in `slack_configs` to be more meaningful for your environment. Also decode `grafana.ini` from the `grafana-config` `Secret`, replace `root_url` with `grafana.int.us-east-1.dev.fakebank.com` for example and re-encode it into the secret.

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
