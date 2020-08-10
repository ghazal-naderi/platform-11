#!/usr/bin/env bash
set -x
PR_BODY="$(<./CHANGELOG.md)"
hub config --global user.email "developers+ci@fakebank.com"
hub config --global user.name "FakeBank Bot"
cd infra
# Read CHANGELOG.md generated above. Using the task output doesn't work for multi-line content.
# Check for an open PR to deploy our app to `int`
OPEN_DEV_PR_NUMBER=$(hub pr list -h "release-int/${REPOSITORY_NAME}" -L1 -f "%I")
if [[ -n "${OPEN_DEV_PR_NUMBER}" ]]; then # we already have an open PR for deploying this app, update it
  # Checkout the open PR we found
  hub pr checkout "${OPEN_DEV_PR_NUMBER}"
  cd k8s/int
  kustomize edit set image "${AWS_ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:${APP_VERSION}"
  hub commit -am "update: \`${REPOSITORY_NAME}\` to \`${APP_VERSION}\`"
  # Push changes to our int release branch and update the PR
  hub push -f -u origin "release-int/${REPOSITORY_NAME}"
  hub issue update "${OPEN_DEV_PR_NUMBER}" -m "Deploy \`${GITHUB_REPOSITORY}\` version \`${APP_VERSION}\` to \`int\`" -m "${PR_BODY}" -l 'release/int,awaiting-review'
else # open a pr
  # Checkout a new branch for the PR
  hub checkout -b "release-int/${REPOSITORY_NAME}"
  cd k8s/int
  kustomize edit set image "${AWS_ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:${APP_VERSION}"
  hub commit -am "update: \`${REPOSITORY_NAME}\` to \`${APP_VERSION}\`"
  # Push the changes up and raise a new PR
  hub push -f -u origin "release-int/${REPOSITORY_NAME}"
  hub pull-request -m "Deploy \`${GITHUB_REPOSITORY}\` version \`${APP_VERSION}\` to \`int\`" -m "${PR_BODY}" -l 'release/int,awaiting-review' -b 'master'
fi
