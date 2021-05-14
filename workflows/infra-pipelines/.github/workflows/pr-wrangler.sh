#!/usr/bin/env bash
set -x
FIRST_RUN="true"
hub config --global user.email "${GITHUB_EMAIL}"
hub config --global user.name "${GITHUB_USER}"

# Set timezone
sudo ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime

# Setup variables about our application
# BASE_REF is the base reference for the PR
# GITHUB_REF points to the merge branch for the PR, this is what we have checked out
# GITHUB_SHA points to the merge commit for the PR
# my-app
IN_PR_APP=$(hub pr show "${IN_PR_NUMBER}" -f "%H" | cut -d'/' -f2-)
# fakebank
IN_PR_ORG=$(echo "${GITHUB_REPO}" | cut -d '/' -f1)

hub checkout "${BASE_REF}"

# Check whether we are already merged, if not then merge
if [[ -n "$(hub pr show "${IN_PR_NUMBER}" -f '%mt')" ]]; then # already merged!
  echo 'Already merged!'
  FIRST_RUN="false"
else
  hub api -XPUT "repos/${GITHUB_REPO}/pulls/${IN_PR_NUMBER}/merge" -f merge_method="squash" -f commit_title="update \`${IN_PR_APP}\` in \`${IN_PR_ENV}\` (#${IN_PR_NUMBER})"
  hub pull
fi

# If we don't have an outgoing env or it is empty, stop here
if [[ -z "${OUT_PR_ENV}" ]]; then
  exit 0
fi

# Now gather information required from output PR
OUT_PR_NUMBER=$(hub pr list -h "release-${OUT_PR_ENV}/${IN_PR_APP}" -L1 -f "%I")

# If we do have a PR open, check out existing branch
if [[ -n "${OUT_PR_NUMBER}" ]]; then
  hub pr checkout "${OUT_PR_NUMBER}"
  # rebase to get current IN_PR_ENV version (it could have changed since OUT_PR_NUMBER was created)
  hub pull --rebase -X ours origin "${BASE_REF}"
else
  hub checkout -b "release-${OUT_PR_ENV}/${IN_PR_APP}"
fi

cd "k8s/${OUT_PR_ENV}" || exit 127

IN_PR_APPURL=$(/tmp/yq e "../${IN_PR_ENV}/kustomization.yaml" -j | jq -r ".images|.[]|select(.name | contains(\"${IN_PR_APP}\"))|.name")
IN_PR_VERSION=$(/tmp/yq e "../${IN_PR_ENV}/kustomization.yaml" -j | jq -r ".images|.[]|select(.name | contains(\"${IN_PR_APP}\"))|.newTag" )
INT_PREV_COMMIT=$(/tmp/yq e "../${OUT_PR_ENV}/kustomization.yaml" -j | jq -r ".images|.[]|select(.name | contains(\"${IN_PR_APP}\"))|.newTag" | cut -d'-' -f2)
INT_CUR_COMMIT=$(/tmp/yq e "../${IN_PR_ENV}/kustomization.yaml" -j | jq -r ".images|.[]|select(.name | contains(\"${IN_PR_APP}\"))|.newTag" | cut -d'-' -f2)
IMAGE="${IN_PR_APPURL}:${IN_PR_VERSION}"
if [ ! -z "${IN_REGISTRY}" ]; then
   OUT_PR_APPURL=$(echo "${IN_PR_APPURL}" | sed -e "s%${IN_REGISTRY}%${OUT_REGISTRY}%")
   IMAGE="${OUT_PR_APPURL}:${IN_PR_VERSION}"
   # Promote images if required
   if [[ "${PROMOTE_IMAGE}" == "true" ]]; then
     mkdir -p "${HOME}/.docker"
     docker login "${IN_DOCKER_SERVER}" -u "${IN_DOCKER_USER}" -p "${IN_DOCKER_PASS}"
     docker pull "${IN_PR_APPURL}:${IN_PR_VERSION}"
     docker tag "${IN_PR_APPURL}:${IN_PR_VERSION}" "${OUT_PR_APPURL}:${IN_PR_VERSION}"
     docker login "${OUT_DOCKER_SERVER}" -u "${OUT_DOCKER_USER}" -p "${OUT_DOCKER_PASS}"
     docker push "${OUT_PR_APPURL}:${IN_PR_VERSION}"
   fi
fi
kustomize edit set image "${IMAGE}"
if hub diff-index --name-only HEAD | grep "k8s/${OUT_PR_ENV}/kustomization.yaml"; then
  hub add kustomization.yaml
  hub commit -m "update \`${IN_PR_APP}\` to \`${IN_PR_VERSION}\` in \`${OUT_PR_ENV}\`"
fi

PREV_COMMIT_DATE=$(hub api "repos/${IN_PR_ORG}/${IN_PR_APP}/commits/${INT_PREV_COMMIT}" | jq -r '.commit.committer.date')
[[ "$PREV_COMMIT_DATE" == "null" ]] && PREV_COMMIT_DATE='1970-01-01'
AFTER_PREV_COMMIT_DATE=$(date --date="${PREV_COMMIT_DATE} + 1 minute" --iso-8601=seconds)
CUR_COMMIT_DATE=$(hub api "repos/${IN_PR_ORG}/${IN_PR_APP}/commits/${INT_CUR_COMMIT}" | jq -r '.commit.committer.date')
[[ "$CUR_COMMIT_DATE" == "null" ]] && CUR_COMMIT_DATE="$(date)"
AFTER_CUR_COMMIT_DATE=$(date --date="${CUR_COMMIT_DATE} + 5 seconds" --iso-8601=seconds)
CUR_PR_DATE=$(hub api "repos/${IN_PR_ORG}/${IN_PR_APP}/commits/${INT_CUR_COMMIT}/pulls" -H "Accept: application/vnd.github.groot-preview+json" | jq -r 'map(.merged_at) | max')
[[ "$CUR_PR_DATE" == "null" ]] && CUR_PR_DATE=AFTER_CUR_COMMIT_DATE
AFTER_CUR_PR_DATE=$(date --date="${CUR_PR_DATE} + 1 second" --iso-8601=seconds)
IN_PR_CHANGELOG=$(octocam -o "${IN_PR_ORG}" -r "${IN_PR_APP}" -f "${AFTER_PREV_COMMIT_DATE}" -t "${AFTER_CUR_PR_DATE}")
IN_PR_CHANGELOG="# \`${IN_PR_APP}:${IN_PR_VERSION}\`
## Changelog
${IN_PR_CHANGELOG}"

if hub push -f -u origin "release-${OUT_PR_ENV}/${IN_PR_APP}"; then
  # Finally, raise a PR for stage or adjust the current one if it already exists
  if [[ "${FIRST_RUN}" == "true" ]]; then
    if [[ -n "${OUT_PR_NUMBER}" ]]; then # we have a PR open, add to it
       hub api "repos/${GITHUB_REPO}/pulls/${OUT_PR_NUMBER}" -X PATCH --field title="Staged release of ${IN_PR_APP}:${IN_PR_VERSION} from ${IN_PR_ENV} to ${OUT_PR_ENV}" # update PR title with new version
       hub api "repos/${GITHUB_REPO}/issues/${OUT_PR_NUMBER}/comments" --field body="${IN_PR_CHANGELOG}" # update via comments
    else # create a PR
       hub pull-request -p -b "${BASE_REF}" -m "Staged release of ${IN_PR_APP}:${IN_PR_VERSION} from ${IN_PR_ENV} to ${OUT_PR_ENV}" -m "${IN_PR_CHANGELOG}" -l "release/${OUT_PR_ENV}"
    fi
  fi
else
echo "no updates required!"
fi
