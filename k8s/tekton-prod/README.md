# tekton-prod
This is a similar configuration to `tekton-pipelines` but made for production deployments.

It will:
- Create a webhook to listen to GitHub release publish events
- Apply the latest full release after validating syntax (only validation for pre-release and drafts)

It assumes:
- You include a fully rendered kustomize in each of your releases named `prod-release-${version}.yaml`, with `${version}` being the tag and version of your release. 

This means that you can either make manual releases via publishing GitHub releases and including the rendered kustomize file or automatically release via the `components/pipelines-for-prod` struct. 

## usage

Overlay as follows, replacing the values with your own:

```
---
apiVersion: tekton.dev/v1alpha1
kind: TaskRun
metadata:
  name: infra-cd-prod-webhook-run
  namespace: tekton-pipelines
spec:
  taskRef:
    name: create-prod-webhook
  inputs:
    params:
    - name: GitHubOrg
      value: "fakebank"
    - name: GitHubUser
      value: "fakeci"
    - name: GitHubRepo
      value: "infra"
    - name: GitHubSecretName
      value: git-webhook
    - name: ExternalDomain
      value: infra-cd-prod.fakebank.com
    - name: WebhookEvents
      value: '[\"release\"]'
  timeout: 1000s
  serviceAccountName: tekton-triggers-createwebhook
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
