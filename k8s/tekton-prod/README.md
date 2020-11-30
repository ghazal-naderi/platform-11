# tekton-prod
This is a similar configuration to `tekton-pipelines` but made for production deployments.

It will:
- Create a webhook to listen to GitHub release publish events
- Apply the latest full release after validating syntax (ending at the validation step for pre-release and drafts)

It assumes:
- You include one or all of the following files in your release with `${version}` being the tag and version of your release:
1. `terraform-${version}.tgz`
2. `kops-cluster-${version}.yaml`
3. `kubernetes-${version}.yaml` 

This means that you can either make manual releases via publishing GitHub releases and including the appropriate deployment files or automatically release via the `components/pipelines-for-prod` struct. 

## usage

Create a secret called `terraform-secrets` in your environment. A few variables should be set:
```
{ 
"AWS_ACCESS_KEY_ID": "",
"AWS_SECRET_ACCESS_KEY": "",
"AWS_REGION": "",
"KOPS_CLUSTER_NAME": "",
"KOPS_STATE_STORE": "",
"TERRAFORM_DIR": "",
}
```
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_REGION` are used for `terraform apply`
- `TERRAFORM_DIR` identifies which terraform directory to apply
- `KOPS_CLUSTER_NAME` and `KOPS_STATE_STORE` are used for `kops update`

You must also have `access-token` defined in your `github-webhook` secret, see `tekton-pipelines` struct for an example.

```
 apiVersion: 'kubernetes-client.io/v1'
 kind: ExternalSecret
 metadata:
   name: terraform-secrets
   namespace: tekton-pipelines
 secretDescriptor:
   backendType: secretsManager
   dataFrom:
     - terraform-secrets
```

Overlay as follows, replacing the values with your own:

```
---
apiVersion: tekton.dev/v1alpha1
kind: TaskRun
metadata:
  name: infra-cd-prod-webhook-run
  namespace: tekton-pipelines
spec:
  params:
  - name: GitHubOrg
    value: fakebank
  - name: GitHubUser
    value: fakeci
  - name: GitHubRepo
    value: infra
  - name: GitHubSecretName
    value: git-webhook
  - name: ExternalDomain
    value: infra-cd-prod.sandbox.11fs-structs.com
  - name: WebhookEvents
    value: '[\"release\"]'
  serviceAccountName: tekton-triggers-createwebhook
  taskRef:
    name: create-prod-webhook
    kind: Task
  timeout: 1000s
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: infra-cd-prod
  namespace: tekton-pipelines
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx-external
spec:
  tls:
  - hosts:
    - infra-cd-prod.fakebank.com
    secretName: infra-cd-prod-tls
  rules:
  - host: infra-cd-prod.fakebank.com
    http:
      paths:
      - path: /
        backend:
          serviceName: el-infra-cd-prod
          servicePort: 8080
```
