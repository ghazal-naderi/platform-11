# kubernetes-lint
This simple workflow is a drop-in option for `infra` repositories that will automatically lint Kubernetes environment definitions and fail if they fail to render, preventing merge of faulty configuration.

It requires no special variables or settings - it simply assumes that all directories under `/k8s` aside from `base` and `apps` are environments to be linted.
