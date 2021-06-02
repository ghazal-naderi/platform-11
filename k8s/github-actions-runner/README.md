# Github Actions Runner Controller
- `actions-runner-controller.yaml` from [here](https://github.com/actions-runner-controller/actions-runner-controller/releases/download/v0.18.2/actions-runner-controller.yaml)
Original source: [here](https://github.com/actions-runner-controller/actions-runner-controller#installation)
## Installation
- Create Github App as per instructions in source repository
- Create a SecretsManager secret (on AWS) or other external secrets provider
```
{
  "github_app_id": "DEFAAAAAAAAAAAAA",
  "github_app_installation_id": "ABCDDDDDDDDDDDDDDDD",
  "github_app_private_key": "$(cat private_key.pem | base64)"
}
```
- Create an ExternalSecret
```
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: controller-manager
  namespace: actions-runner-system
secretDescriptor:
  backendType: secretsManager
  dataFrom:
  - github-actions-controller-app
```
- Create one or more `RunnerDeployment` CRDs with autoscaling based on repository, this is an example and further configurations are available in upstream docs
```
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: example-runner-deployment
spec:
  template:
    spec:
      repository: my-github-org/my-repo
      env: []
---
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: example-runner-deployment-autoscaler
spec:
  scaleTargetRef:
    name: example-runner-deployment
  minReplicas: 1
  maxReplicas: 3
  metrics:
  - type: TotalNumberOfQueuedAndInProgressWorkflowRuns
    repositoryNames:
    - my-github-org/my-repo
```
