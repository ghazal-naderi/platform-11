#!/usr/bin/env bash
set -x
hub config --global user.email "developers+ci@fakebank.com"
hub config --global user.name "FakeBank Bot"
ENVIRONMENT=""
case $GITHUB_LABELS in
    *"release/qa"*)
        ENVIRONMENT="qa"
        ;;
    *"release/prod"*)
        ENVIRONMENT="production"
        ;;
    *)
        exit 127
        ;;
esac
echo "env: $ENVIRONMENT"
BRANCH="release-${ENVIRONMENT}/rolling"
IMAGE_VERSION="${COMMENT#/pin }"
regex='.*\/.* .*-.*'

[[ "${IMAGE_VERSION}" =~ $regex ]] || exit 127
IMAGE=$(echo "${IMAGE_VERSION}" | cut -d' ' -f1)
FRIENDLY_IMAGE=$(echo "${IMAGE}" | cut -d'/' -f2)
VERSION=$(echo "${IMAGE_VERSION}" | cut -d' ' -f2)
git checkout "${BRANCH}"
git pull
cd "k8s/${ENVIRONMENT}"

kustomize edit set image "${IMAGE}:${VERSION}"
git add kustomization.yaml
git commit -m "pin \`${FRIENDLY_IMAGE}\` to \`${VERSION}\` in \`${ENVIRONMENT}\`"
git push