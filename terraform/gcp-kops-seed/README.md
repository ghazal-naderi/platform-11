# gcp-kops-seed
This Terraform module will create the most basic components required for a `kops` cluster.

Before applying this, you should export the following:
- `GOOGLE_CLOUD_PROJECT` being the destination GCP project
- `GOOGLE_APPLICATION_CREDENTIALS` being your credentials file
- `GOOGLE_REGION` being your destination region (eg. us-central1)
- `GOOGLE_ZONE` being your destination zone, (eg. us-central1-c)
- `KOPS_FEATURE_FLAGS=AlphaAllowGCE` to allow GCP features

You must pass in the variables:
`region`: eg. us-central1
`environment` - eg. dev
`project` - eg. myproject
`domain` - eg. dev.us-central-1.myproject.com.

Remember to create the `domain` DNS zone in the parent zone DNS management system, too - you'll need to ensure the NS records are created appropriately and test that everything is working correctly before creating the cluster.

When creating the cluster, ensure that you set `KOPS_STATE_STORE=${gcs_bucket}` with `${gcs_bucket}` being the bucket created by this module and `KOPS_DOMAIN=${domain}` with `${domain}` being the target domain to deploy to. This module has also created a service account that you should export as `KOPS_SERVICE_ACCOUNT=${account}` with `${account}` being it's fully qualified name.

```
export KOPS_STATE_STORE=gs://fakebank-stage-state
export KOPS_DOMAIN=dev.us-central1.myproject.com
export KOPS_SERVICE_ACCOUNT=us-central1-dev-myproject-k8s@projectname.iam.gserviceaccount.com
kops create cluster ${KOPS_DOMAIN} \
    --gce-service-account=${KOPS_SERVICE_ACCOUNT} \
    --state "${KOPS_STATE_STORE}" \
    --zones "us-central1-a,us-central1-b,us-central1-c" \
    --networking cilium \
    --dns public \
    --node-count 3 \
    --node-size n1-standard-2 \
    --kubernetes-version 1.18.8 \
    --master-size n1-standard-1 \
    --master-count 3
```
Note that there's currently no need for `--bastion` or `--private` as private GCP is not currently supported on Kops as per [kops#9832](https://github.com/kubernetes/kops/pull/9832). This simply means that all nodes will receive a public IP address by default, make sure that you adjust firewall rules in order to protect them.

Note that the GCP default images come with limitations - all volumes are mounted as `noexec` obstensibly for security, this can return `permission denied` errors when attempting to run standard images from structs (most notably Tekton and Elasticsearch). In order to get around this limitation, use the CentOS images (eg. `centos-cloud/centos-8-v20200910`) by editing the kops instance groups (eg. `kops edit ig nodes-us-central1-{a,b,c}`) for nodes. The core Kubernetes stack runs just fine with these limitations and we don't expect to run arbitrary workloads on masters so they do not require this change.

For DNS, we should edit with `kops edit cluster` in order to add:

```
spec:
  kubeDNS:
    provider: CoreDNS
```
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
      enableNodePort: true
      version: v1.8.2
```
For metrics monitoring, we should edit in order to add:
```
kubelet:
    authenticationTokenWebhook: true
    authorizationMode: Webhook
```
For RBAC, we should add:
```
  authorization:
    rbac: {}
  kubeAPIServer:
    authorizationMode: RBAC
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
