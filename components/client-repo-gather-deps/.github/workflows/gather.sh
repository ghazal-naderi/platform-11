#!/bin/bash -x 
set -eu -o pipefail
COUNT=$(( $(./yq r manifest.yaml --length packages) - 1 ))
sudo rm -rf temp/ || mkdir temp/
git config user.email "bot@11fs.com"
git config user.name "11:FS Bot"
render_package() {
            local pname=${1}
            local pref=${2}
            local path=${3}
            local prelease=${4}
            mkdir -p "temp/${pname}"
            sudo rm -rf "${path}"
            git clone -c advice.detachedHead=false --quiet --progress "https://${GITHUB_SECRET_TOKEN}@github.com/11FSConsulting/platform.git" "temp/${pname}"
            (cd "temp/${pname}" && git checkout "${pref}")
            sudo rm -rf "temp/${pname}/.git"
            (cd "temp/${pname}" && docker run -e "RELEASE=${prelease}" -e "LINT=no" -v "$(pwd):/workspace" -t platform/infra-tester)
            if [[ "${path}" =~ k8s/.* ]]; then
                git rm -f "${path}.yaml" || echo "path not found" 
                mkdir -p "$(echo "${path}" | rev | cut -d'/' -f2- | rev)"  || echo "mkdir failed"
                cp "temp/${pname}/pkg/${pname}.yaml" "${path}.yaml"
                git add "${path}.yaml"
            else
              git rm -r -f "${path}" || mkdir -p "${path}"
              cp -r "temp/${pname}/pkg/${pname}/" "${path}"
              git add "${path}"
            fi
            sudo rm -rf "temp/${pname}"
}

for package in $(seq 0 "${COUNT}"); do 
    pname="$(./yq r manifest.yaml "packages[${package}].name")"
    defaultref="master"
    pref="$(./yq r manifest.yaml "packages[${package}].ref")"
    pref="${pref:-$defaultref}"
    path="$(./yq r manifest.yaml "packages[${package}].path")"
    prelease="$(./yq r manifest.yaml "packages[${package}.release")"
    prelease="${prelease:platform}"
    defaultpath="structs/${pname}"
    path="${path:-$defaultpath}"
    render_package "${pname}" "${pref}" "${path}" "${prelease}"
done

if git commit -m 'Vendor dependencies'; then
  git remote set-url origin "https://${GITHUB_SECRET_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
  git push origin "HEAD:${GITHUB_HEAD_REF}"
  echo "changes committed"
else
  echo "no changes for commit"
fi
