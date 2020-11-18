# client-repo-gather-deps
This repo includes a GitHub Action and manifest.yml file that together can be used to initialize a new client or `infra` repository with the necessary code to automatically obtain and vendor dependencies from this `platform` repository. 

* Copy `.github` directory into `$project/infra`
* Add the secrets `AWS_PLATFORM_ECR_ACCESS_KEY_ID` and `AWS_PLATFORM_ECR_SECRET_ACCESS_KEY` to `$project/infra` with the AWS account that only has access to read the `platform/infra-tester` image from ECR (see `terraform/aws-ecr`)
* Add the secret `GH_BOT_SECRET_TOKEN` to `$project/infra` with a Personal Access Token for your git bot that has read/write access to `$project/infra` and read access to `11FSConsulting/platform`
* Commit the `.github` directory and add a `manifest.yaml` to the root of `$project/infra` with content like:
```yaml
packages:
   - name: terraform/iam-compartment
     ref: master
```
* Every time `manifest.yaml` is updated, it will trigger a re-gather of all dependencies
