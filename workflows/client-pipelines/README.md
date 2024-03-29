# pipelines-for-prod (client component)
Use this with the infra component (infra/pipelines)
## requirements
- `tekton` for non-final environments (to be updated in code)
- `tekton-prod` for final environments (to be updated by release)

## description
This is a collection of GHA pipelines to manage the process of shipping code from one to many 'client' Kotlin microservices all the way to production.

It makes the following assumptions:
- A bot user is configured with access to all relevant repositories
- Kotlin services each have their own repository and are compiled with maven
- An `infra` repository contains the declaration for each environment as in the template 11FSConsulting/infra
- In this example implementation, there are 3 Kubernetes environments - `int` for integration testing, `qa` for QA/UAT approval and `production` for end-user facing services with Tekton installed and configured as per the included struct.
- In this example implementation, there are GitHub teams `qa` and `back-end` containing appropriate users to approve changes to production

It has a lot of configurability and you may rename or re-order the environments or approval teams as required. `pr-wrangler.sh` doesn't have any particular knowledge of the chain of environments, only that there is an incoming (eg. int) environment and an outgoing (eg. qa) environmnet. You may create copies of these workflow yamls and arrange them in whatever way makes sense for your implementation.

It provides the means to automatically:
- Merge changes made to applications `master` branches into an environment with a changelog
- Raise and maintain (including rebasing) a single rolling branch/PR per service against another environment with version updates made to a previous environment, mergable by the QA team
- Pin particular versions by submitting a message like `/pin $IMAGE $VERSION` with `$IMAGE` being the fully qualified image name and `$VERSION` being the version number.
- Raise and maintain (including rebasing) a single rolling branch/PR per service against a final (eg. `production`) environment with version updates made to a previous environment, mergeable by a backend engineer alongside a member of the QA team
- Make a draft release from changes approved into a final environment (eg. `production`), either as an ad-hoc change (made by labelling a PR) or through the aforementioned standard lifecycle

## installation
You must change:
- AWS: Secrets `AWS_ECR_ACCOUNT_ID`, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to those configured to access the appropriate ECR repository for your images or change client workflows to obtain images from elsewhere.
- AWS: `AWS_REGION` in client workflows to match your own ECR's region in AWS.
- AWS: Enable the `aws` configuration block if using AWS
- OCI: Enable the `oci` configuration block and adjust the values within  
- Docker images promotion: Enable PROMOTE_IMAGE by setting it to "true" and set `IN_REGISTRY`, `IN_DOCKER_SERVER`, `IN_DOCKER_USER`, `IN_DOCKER_PASS`, `OUT_REGISTRY`, `OUT_DOCKER_SERVER`, `OUT_DOCKER_USER` and `OUT_DOCKER_PASS`. 
- Secrets `GH_PAT`, `GH_BOT_UNAME` and `GH_BOT_EMAIL` to reflect your GitHub bot's secret access token, username and email address.
- Secret `CICD_TARGET_ENV` to indicate your target environment for the first PR in the chain (Eg. `int`), this should map to a directory in `k8s`
- Secret `JDK_VERSION` to indicate your preferred JDK version (Eg. `11`)
- Secret `NEXUS_URL` and `NEXUS_PASSWORD` to your Sonatype Nexus 3 URL (minus trailing slash) and developer account password.

Additionally, the GitHub teams required for approval at each phase can be changed in the YAML files. The order of environments is defined by the YAML files which can be copied and used as a template to scale to as many environments as required.

The end effect of this is a full Continuous Deployment workflow with however many manual approval gates are required.
