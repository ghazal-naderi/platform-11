#!/usr/bin/env bash
set -x
hub config --global user.email "developers+ci@fakebank.com"
hub config --global user.name "FakeBank Bot"
hub config --global pull.rebase "true"

GITHUB_ORG=$(echo "${GITHUB_REPO}" | cut -d '/' -f1)

# Check whether we are already merged, if not then merge
if [[ -n "$(hub pr show "${QA_PR_NUMBER}" -f '%mt')" ]]; then # already merged!
  exit 0
else
  hub api -XPUT "repos/${GITHUB_REPO}/pulls/${QA_PR_NUMBER}/merge" -f merge_method="squash" -f commit  _title="rolling \`qa\` release (#${QA_PR_NUMBER})"
  git checkout "$BASE_REF"
  git pull
fi

# Now gather information required from Prod and Preprod PRs
PROD_PR_NUMBER=$(hub pr list -h 'release-prod/rolling' -L1 -f "%I")
# If we do have a prod PR open, check out existing branch
if [[ -n "${PROD_PR_NUMBER}" ]]; then
  hub pr checkout "${PROD_PR_NUMBER}"
  git pull --rebase origin "${BASE_REF}" 
else
  git checkout -b "release-prod/rolling" 
fi

cd k8s/production || exit 127

PR_CHANGELOGS=""

# Loop over all images, gathering the versions from Stage for Prod
STAGE_IMAGE_COUNT=$(/tmp/yq r "../qa/kustomization.yaml" 'images' --length)
STAGE_IMAGE_COUNT=$((STAGE_IMAGE_COUNT-1)) # Decrement STAGE_IMAGE_COUNT to avoid off-by-one
for i in $(seq 0 ${STAGE_IMAGE_COUNT}); do
  IMAGE_URL=$(/tmp/yq r "../qa/kustomization.yaml" "images[$i].name")
  IMAGE_VERSION=$(/tmp/yq r "../qa/kustomization.yaml" "images[$i].newTag")
  PREV_COMMIT=$(grep -A1 "${IMAGE_URL}" kustomization.yaml | grep -Eo 'newTag: (.*)' | cut -d'-' -f2)
  CURR_COMMIT=$(echo "${IMAGE_VERSION}" | cut -d'-' -f2)
  IMAGE=$(echo "${IMAGE_URL}" | cut -d'/' -f2)
  kustomize edit set image "${IMAGE_URL}:${IMAGE_VERSION}"
  if git diff-index --name-only HEAD | grep 'k8s/production/kustomization.yaml'; then
    git add kustomization.yaml
    PREV_COMMIT_DATE=$(hub api "repos/${GITHUB_ORG}/${IMAGE}/commits/${PREV_COMMIT}" | jq -r '.commit.committer.date')
    [[ "$PREV_COMMIT_DATE" == "null" ]] && PREV_COMMIT_DATE='1970-01-01'
    CURR_COMMIT_DATE=$(hub api "repos/${GITHUB_ORG}/${IMAGE}/commits/${CURR_COMMIT}" | jq -r '.commit.committer.date')
    [[ "$CUR_COMMIT_DATE" == "null" ]] && CUR_COMMIT_DATE="$(date)"
    PR_CHANGELOG=$(octocam -o "${GITHUB_ORG}" -r "${IMAGE}" -f "${PREV_COMMIT_DATE}" -t "${CURR_COMMIT_DATE}")
    PR_CHANGELOG="# \`${IMAGE}:${IMAGE_VERSION}\`
## Changelog
${PR_CHANGELOG}"
    PR_CHANGELOGS="${PR_CHANGELOG}
${PR_CHANGELOGS}"
    APP_NAME=$(echo "${IMAGE_URL}" | cut -d'/' -f2)
    git commit -m "update \`${APP_NAME}\` to \`${IMAGE_VERSION}\` in \`prod\`" || echo "no update required"
  fi
done

# Finally, create a PR against production or adjust the current one if it already exists
if [[ -n "${PROD_PR_NUMBER}" ]]; then # we have a prod PR open, add to it
   git push -f
   hub issue update "${PROD_PR_NUMBER}" -m "Staged release from QA to Prod" -m "${PR_CHANGELOGS}" -l "release/prod"
else # create a prod PR
   git push -u origin release-prod/rolling
   hub pull-request -p -b "${BASE_REF}" -m "Staged release from QA to Prod" -m "${PR_CHANGELOGS}" -l "release/prod" 
fi
