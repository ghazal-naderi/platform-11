#!/bin/bash -x 
set -eu -o pipefail
COUNT=$(( $(./yq r manifest.yaml --length repos) - 1 ))
git config user.email "bot@11fs.com"
git config user.name "11:FS Bot"
clone_repo() {
            local rname=${1}
            local rref=${2}
            local rgithub=${3}
            mkdir -p "structs"
            rm -rf "structs/${rname}"
            git clone -c advice.detachedHead=false --quiet --depth=1 --progress -b "${rref}" "https://${GITHUB_SECRET_TOKEN}@github.com/${rgithub}.git" "structs/${rname}"
            rm -rf "structs/${rname}/.git"
}

for repo in $(seq 0 "${COUNT}"); do
    rname=$(./yq r manifest.yaml "repos[${repo}].name")
    rgithub=$(./yq r manifest.yaml "repos[${repo}].github")
    rref=$(./yq r manifest.yaml "repos[${repo}].ref")
    clone_repo "${rname}" "${rref}" "${rgithub}"
    if [ -f "structs/${rname}" ]; then 
        if [ -f "structs/${rname}/build.sh" ]; then
            (cd "structs/${rname}" && ./build.sh)
        fi
    fi
done

(cd structs && docker run -e LINT=no -v "$(pwd):/workspace" -t platform/infra-tester)
mv structs/pkg .structs
git rm --cached -r .structs
for repo in $(seq 0 "${COUNT}"); do
  rname=$(./yq r manifest.yaml "repos[${repo}].name")
  scount=$(./yq r manifest.yaml --length "repos[${repo}].packages")
  for struct in $(seq 0 "${scount}"); do
    sname=$(./yq r manifest.yaml "repos[${repo}].packages[${struct}].name") 
    stype=$(./yq r manifest.yaml "repos[${repo}].packages[${struct}].type") 
    git add ".structs/${stype}/${sname}"*
  done
done

if git commit -m 'Vendor dependencies'; then
  git remote set-url origin "https://${GITHUB_SECRET_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
  git push origin "HEAD:${GITHUB_HEAD_REF}"
else
  echo "no changes for commit"
fi
