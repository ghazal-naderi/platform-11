#!/usr/bin/env bash
set -x
hub config --global user.email "developers+ci@fakebank.com"
hub config --global user.name "FakeBank Bot"
hub config --global pull.rebase "true"

# Setup variables about our application
# BASE_REF is the base reference for the PR
# GITHUB_REF points to the merge branch for the PR, this is what we have checked out
# GITHUB_SHA points to the merge commit for the PR
# fakebank/my-app
INT_PR_APP=$(hub pr show "${INT_PR_NUMBER}" -f "%t" | sed -e 's/Deploy `//' -e 's/` version.*$//')
# fakebank
INT_PR_ORG=$(echo "${INT_PR_APP}" | cut -d '/' -f1)
# my-app
INT_PR_IMAGE=$(echo "${INT_PR_APP}" | cut -d '/' -f2)
# 1.2.3-ffffff
INT_PR_VERSION=$(hub pr show "${INT_PR_NUMBER}" -f "%t" | sed -e 's/Deploy.*version `//g' -e 's/` to .*$//g')
# ffffff
INT_CUR_COMMIT=$(echo "${INT_PR_VERSION}" | cut -d'-' -f2)
# aaaaaa
INT_PREV_COMMIT=""

# Check whether we are already merged, if not then merge
# FIXME: A race condition occurs if too many PRs are merged for the same component in quick succession
if [[ -n "$(hub pr show "${INT_PR_NUMBER}" -f '%mt')" ]]; then # already merged!
  exit 0
else
  hub api -XPUT "repos/${GITHUB_REPO}/pulls/${INT_PR_NUMBER}/merge" -f merge_method="squash" -f commit_title="update \`${INT_PR_IMAGE}\` to \`${INT_PR_VERSION}\` in \`int\` (#${INT_PR_NUMBER})"
  git checkout "$BASE_REF"
  git pull
fi

# Now gather information required from Preprod and Dev PRs
QA_PR_NUMBER=$(hub pr list -h "release-qa/rolling" -L1 -f "%I")
# If we do have a qa PR open, check out existing branch
if [[ -n "${QA_PR_NUMBER}" ]]; then
  hub pr checkout "${QA_PR_NUMBER}"
  git pull --rebase origin "${BASE_REF}" 
else
  git checkout -b release-qa/rolling
fi

cd k8s/qa || exit 127

# Loop over all images, gathering the version from Dev for Preprod where it matches the PR
INT_IMAGE_COUNT=$(/tmp/yq r "../int/kustomization.yaml" 'images' --length)
INT_IMAGE_COUNT=$((INT_IMAGE_COUNT-1)) # Decrement INT_IMAGE_COUNT to avoid off-by-one
for i in $(seq 0 ${INT_IMAGE_COUNT}); do
  IMAGE_URL=$(/tmp/yq r "../int/kustomization.yaml" "images[$i].name")
  IMAGE_VERSION=$(/tmp/yq r "../int/kustomization.yaml" "images[$i].newTag")
  if echo "${IMAGE_URL}" | grep -q "${INT_PR_IMAGE}"; then
     INT_PREV_COMMIT=$(grep -A1 "${INT_PR_IMAGE}" kustomization.yaml | grep -Eo 'newTag: (.*)' | cut -d'-' -f2)
     IMAGE="${IMAGE_URL}:${IMAGE_VERSION}"
     kustomize edit set image "${IMAGE}"
     if git diff-index --name-only HEAD | grep 'k8s/qa/kustomization.yaml'; then
       git add kustomization.yaml
       git commit -m "update \`${INT_PR_IMAGE}\` to \`${IMAGE_VERSION}\` in \`qa\`"
     fi
  fi
done

PREV_COMMIT_DATE=$(hub api "repos/${INT_PR_APP}/commits/${INT_PREV_COMMIT}" | jq -r '.commit.committer.date')
[[ "$PREV_COMMIT_DATE" == "null" ]] && PREV_COMMIT_DATE='1970-01-01'
CUR_COMMIT_DATE=$(hub api "repos/${INT_PR_APP}/commits/${INT_CUR_COMMIT}" | jq -r '.commit.committer.date')
[[ "$CUR_COMMIT_DATE" == "null" ]] && CUR_COMMIT_DATE="$(date)"
INT_PR_CHANGELOG=$(octocam -o "${INT_PR_ORG}" -r "${INT_PR_IMAGE}" -f "${PREV_COMMIT_DATE}" -t "${CUR_COMMIT_DATE}")
INT_PR_CHANGELOG="# \`${INT_PR_IMAGE}:${INT_PR_VERSION}\`
## Changelog
${INT_PR_CHANGELOG}"
# Finally, raise a PR for stage or adjust the current one if it already exists
if [[ -n "${QA_PR_NUMBER}" ]]; then # we have a qa PR open, add to it
   git push -f
   hub api "repos/${GITHUB_REPO}/issues/${QA_PR_NUMBER}/comments" --field body="${INT_PR_CHANGELOG}" # update via comments
else # create a qa PR
   git push -u origin release-qa/rolling
   hub pull-request -p -b "${BASE_REF}" -m "Staged release from Int to QA" -m "${INT_PR_CHANGELOG}" -l 'release/qa'
fi
