# terraform-lint
This simple workflow is a drop-in option for `infra` repositories that will automatically lint Terraform environment definitions and fail if they fail to render, preventing merge of faulty configuration.

It requires no special variables or settings - it simply assumes that all directories under `/terraform` aside from `structs` are environments to be linted.
