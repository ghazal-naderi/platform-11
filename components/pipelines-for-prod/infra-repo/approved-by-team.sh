#!/usr/bin/env bash
github_api() {
    curl -sL -XGET --user "${GITHUB_USER}:${GITHUB_TOKEN}" "https://api.github.com/$1"
}
APPROVAL_IDS=($(github_api "repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/reviews" | jq -r ".[] | select(.state == \"APPROVED\") | .id"))
ORG=$(echo "${GITHUB_REPOSITORY}" | cut -d'/' -f1)
for approval in "${APPROVAL_IDS[@]}"; do
  user=$(github_api "repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/reviews/${approval}" | jq -r '.user.login')
  team_membership=$(github_api "orgs/${ORG}/teams/${TEAM}/memberships/${user}" | jq -r '.state')
  [[ "${team_membership}" == "active" ]] && exit 0
done
exit 1
