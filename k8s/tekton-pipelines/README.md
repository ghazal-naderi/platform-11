# tekton-pipelines
## introduction
This struct provides the core of our CI/CD pipeline for Kubernetes - it includes all the CRDs and code necessary to automatically render and deploy Terraform HCL and Kustomize YAML to Kubernetes clusters.
## updates
*pipeline:* `v0.16.2`
*triggers:* `v0.8.1`
*dashboard:* `v0.9.0`
*git-clone:* `0.2-88bc2b5`

To update this struct, simply:
```
curl -Lo pipelines.yaml https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
curl -Lo triggers.yaml https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
curl -Lo dashboard.yaml https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
curl -Lo git-clone.yaml https://raw.githubusercontent.com/tektoncd/catalog/master/task/git-clone/0.2/git-clone.yaml
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
apiVersion: v1
kind: ServiceAccount
metadata:
  name: build-bot
  namespace: tekton-pipelines
secrets:
- name: git-ssh-key
- name: git-web-key
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: infra-build-bot
  namespace: tekton-pipelines
secrets:
- name: git-ssh-key
- name: git-web-key
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: tekton-dashboard
  namespace: tekton-pipelines
  annotations:
    kubernetes.io/ingress.class: nginx-external
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    cert-manager.io/acme-challenge-type: http01
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
  name: infra-cd
  namespace: tekton-pipelines
spec:
  params:
  - default: k8s/sandbox
    description: The path to the kustomize dir we're applying, relative to repo root
    name: kustomizeDir
  - default: https://github.com/11fsconsulting/infra.git
    description: The path to the Github repository we should apply
    name: git-url
  - default: master
    description: The revision or tag to apply
    name: git-revision
  tasks:
  - name: fetch-from-git
    params:
    - name: url
      value: $(params.git-url)
    - name: revision
      value: $(params.git-revision)
    taskRef:
      name: git-clone
    workspaces:
    - name: output
      workspace: git-source
  - name: apply-k8s
    params:
    - name: kustomizeDir
      value: "$(params.kustomizeDir)"
    runAfter:
    - fetch-from-git
    taskRef:
      kind: ClusterTask
      name: kustomize-apply
    workspaces:
    - name: source
      workspace: git-source
  workspaces:
  - name: git-source
---
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: terraform-cd
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
  workspaces:
    - name: git-source
  tasks:
  - name: fetch-from-git
    taskRef:
      name: git-clone
    params:
      - name: url
        value: $(params.git-url)
      - name: revision
        value: $(params.git-revision)
    workspaces:
      - name: output
        workspace: git-source
  - name: apply-tf
    runAfter: [fetch-from-git]
    taskRef:
      name: terraform-apply
      kind: ClusterTask
    params:
    - name: terraformDir
      value: "$(params.terraformDir)"
    workspaces:
      - name: source
        workspace: git-source
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
