# pipelines-for-prod
This is a collection of GHA pipelines to manage the process of shipping code from one to many 'client' Kotlin microservices all the way to production.

It makes the following assumptions:
- A bot user is configured with access to all relevant repositories
- Kotlin services each have their own repository and are compiled with maven
- An `infra` repository contains the declaration for each environment as in the template 11FSConsulting/infra
- There are 3 Kubernetes environments - `int` for integration testing, `qa` for QA/UAT approval and `production` for end-user facing services with Tekton installed and configured as per the included struct.
- There are GitHub teams `qa` and `development-leads` containing appropriate users

It provides the means to automatically:
- Automatically merge changes made to applications `master` branches into the `int` environment with a changelog
- Lint all changes made to k8s code in order to verify that they are syntactically valid.
- Raise and maintain a rolling branch/PR against the `qa` environment with version updates made to `int`, mergable by the QA team
- Pin particular versions by submitting a message like `/pin $IMAGE $VERSION` with `$IMAGE` being the fully qualified image name and `$VERSION` being the version number.
- Raise and maintain a rolling branch/PR against the `production` environment with version updates made to `qa`, mergeable by the lead developer and QA team
- Make a production release from changes approved into `production`, either as an ad-hoc change (made by labelling a PR) or through the aforementioned standard lifecycle

You must change:
- Secrets `AWS_ECR_ACCOUNT_ID`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to those configured to access the appropriate ECR repository for your images or change client workflows to obtain images from elsewhere. 
- `AWS_REGION` in client workflows to match your own ECR's region in AWS.
- Secret `GH_PAT` to reflect your GitHub bot's secret access token.
- Git `user.name` and `user.email` in bash scripts to your own preferred Git username/user email for commits.
- `fakeci` in workflows to your GitHub bot's username.
- `fakebank` in workflows to your GitHub org name.

The end effect of this is a full Continuous Deployment workflow with a manual approval gate at each environment. 
