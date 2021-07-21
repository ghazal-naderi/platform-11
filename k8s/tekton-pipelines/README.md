# tekton-pipelines
## introduction
This struct provides the core of our CI/CD pipeline for Kubernetes - it includes all the CRDs and code necessary to automatically render and deploy Terraform HCL, Kops YAML and Kustomize YAML to Kubernetes clusters and clouds.
## updates
*pipeline:* `v0.26.0`
*triggers:* `v0.15.0`
*dashboard:* `v0.18.1`, `read only` version with `--namespace=tekton-pipelines`
*git-clone:* `0.4-d517969`

To update this struct, simply:
```
curl -Lo pipelines.yaml https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
curl -Lo triggers.yaml https://storage.googleapis.com/tekton-releases/triggers/previous/v0.15.0/release.yaml
curl -Lo interceptors.yaml https://storage.googleapis.com/tekton-releases/triggers/previous/v0.15.0/interceptors.yaml
curl -Lo dashboard.yaml https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release-readonly.yaml
sed -i dashboard.yaml -e 's/--namespace=/--namespace=tekton-pipelines/'
curl -Lo git-clone.yaml https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.4/git-clone.yaml 
```

Though please be sure to update the versions above!

## installation
Apply the output of kustomize.

In order to kustomize for a specific git repository and cluster:

- Generate a secret string to be used by webhooks with eg. `ruby -rsecurerandom -e 'puts SecureRandom.hex(20)'`

- Use the output of the previous step to create secrets in the storage system of choice (eg. Vault, AWS Secrets Manager) to be used as `ExternalSecrets`. 

```
git-webhook: 
  username: <github username>
  access-token: <github PAT>
  secret-string: <output of first step>

git-ssh-key:
  ssh-privatekey: <private PEM added to github account>
```

- Add one or more secret environment variables for Terraform in your secret management system to be read into the runner's environment, eg.
```
{ "AWS_ACCESS_KEY_ID": "ABCDEF",
"AWS_SECRET_ACCESS_KEY": "/o/o/o/o/"
"AWS_DEFAULT_REGION": "us-east-1",
"GOOGLE_CLOUD_CREDENTIALS": "FFFFFFFFFFFAAAAAAAAAXM"}
```

- Create `ExternalSecrets` for `terraform-secrets`, `git-ssh-key` and `git-web-key` like so:
```
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: git-ssh-key
  namespace: tekton-pipelines
spec: 
  template:
    metadata:
      annotations:
        tekton.dev/git-0: github.com
    type: kubernetes.io/ssh-auth
  backendType: secretsManager
  data:
      - key: git-ssh-key
        property: ssh-privatekey
        name: ssh-privatekey
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: git-web-key
  namespace: tekton-pipelines
spec: 
  template:
    metadata:
      annotations:
        tekton.dev/git-0: https://github.com
    type: kubernetes.io/basic-auth
  backendType: secretsManager
  data:
      - key: git-webhook
        property: username
        name: username
      - key: git-webhook
        property: access-token
        name: password
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: git-webhook
  namespace: tekton-pipelines
secretDescriptor:
  backendType: secretsManager
  dataFrom:
    - git-webhook
---
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

- Create `tekton-custom.yaml` for your own cluster like so, replacing the URLs as appropriate:
```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: tekton-dashboard
  namespace: tekton-pipelines
  annotations:
    kubernetes.io/ingress.class: nginx-external
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/auth-signin: https://auth.sandbox.11fs-structs.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    nginx.ingress.kubernetes.io/auth-url: https://auth.sandbox.11fs-structs.com/oauth2/auth
spec:
  tls:
  - secretName: tekton-dashboard-tls
    hosts:
    - tekton.sandbox.11fs-structs.com
  rules:
  - host: tekton.sandbox.11fs-structs.com
    http:
      paths:
      - backend:
          serviceName: tekton-dashboard
          servicePort: 9097
``` 

- Override the TaskRun and Pipelines like so, changing the path and URLs to your own environments'
```
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: infra-cd-webhook-run
  namespace: tekton-pipelines
spec:
  taskRef:
    name: create-webhook
  params:
  - name: GitHubOrg
    value: "11FSConsulting"
  - name: GitHubUser
    value: "11fs-cicd"
  - name: GitHubRepo
    value: "infra"
  - name: GitHubSecretName
    value: git-webhook
  - name: ExternalDomain
    value: infra-updater.sandbox.11fs-structs.com
  timeout: 1000s
  serviceAccountName: tekton-triggers-createwebhook
---
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: kops-cd
  namespace: tekton-pipelines
spec:
  params:
  - name: kopsFile
    description: The path to the kops file we're applying, relative to repo root
    default: k8s/sandbox.yaml
  - name: git-url
    description: The path to the Github repository we should apply
    default: https://github.com/11fsconsulting/infra.git
  - name: git-revision
    description: The revision or tag to apply
    default: master
---
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: infra-cd
spec:
  params:
  - name: kustomizeDir
    description: The path to the kustomize dir we're applying, relative to repo root
    default: k8s/sandbox
  - name: git-url
    description: The path to the Github repository we should apply
    default: https://github.com/11fsconsulting/infra.git
  - name: git-revision
    description: The revision or tag to apply
    default: master
---
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: terraform-cd
  namespace: tekton-pipelines
spec:
  params:
  - name: terraformDir
    description: The path to the terraform dir we're applying, relative to repo root
    default: terraform/sandbox
  - name: git-url
    description: The path to the Github repository we should apply
    default: https://github.com/11fsconsulting/infra.git
  - name: git-revision
    description: The revision or tag to apply
    default: master
---
```

- Override the webhook Ingress like so, changing the URL to your own environment's
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: infra-cd
  namespace: tekton-pipelines
  annotations:
    cert-manager.io/issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx-external
spec:
  tls:
  - hosts:
    - infra-updater.sandbox.11fs-structs.com
    secretName: infra-cd-tls
  rules:
  - host: infra-updater.sandbox.11fs-structs.com
    http:
      paths:
      - path: /
        backend:
          serviceName: el-infra-cd
          servicePort: 8080
```
