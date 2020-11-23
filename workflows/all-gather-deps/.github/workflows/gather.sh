#!/bin/bash -x 
set -eu -o pipefail
COUNT=$(( $(./yq r manifest.yaml --length packages) - 1 ))
sudo rm -rf temp/ || mkdir temp/

git config --global user.name "11:FS Bot"
git config --global user.email "consulting-eng-platform+bot@11fs.com"

render_ref() {
  local pref="${1}"
  local prelease="${2}"
  if [[ ! -d "temp/refs/${pref}/${prelease}" ]]; then 
    hub clone --depth 1 --branch "${pref}" --single-branch "https://${GITHUB_TOKEN}@github.com/11FSConsulting/platform.git" "temp/refs/${pref}/${prelease}"
    (cd "temp/refs/${pref}/${prelease}" && docker run -e "RELEASE=${prelease}" -e "LINT=no" -v "$(pwd):/workspace" -t platform/infra-tester)
  fi
}

render_package() {
            local pname="${1}"
            local pref="${2}"
            local path="${3}"
            local prelease="${4}"
            mkdir -p "temp/refs/${pref}"
            [[ "${path}" != ".github/workflows" ]] && sudo rm -rf "${path}"
            render_ref "${pref}" "${prelease}"
            if [[ "${path}" =~ k8s/.* ]]; then
                hub rm -f "${path}.yaml" || echo "path not found" 
                mkdir -p "$(echo "${path}" | rev | cut -d'/' -f2- | rev)" || echo "mkdir failed"
                cp "temp/refs/${pref}/${prelease}/pkg/${pname}.yaml" "${path}.yaml"
                hub add "${path}.yaml"
            elif [[ "${path}" == ".github/workflows" ]]; then
                mkdir -p "${path}"
                for f in "temp/refs/${pref}/${prelease}/pkg/${pname}/.github/workflows/"*; do 
                    cp "${f}" ".github/workflows/"
                done
                hub add .github/workflows/
            else
              hub rm -r -f "${path}" || mkdir -p "${path}"
              sudo rm "temp/refs/${pref}/${prelease}/pkg/${pname}/"*.md || echo "didn't detect any documentation to remove"
              cp -r "temp/refs/${pref}/${prelease}/pkg/${pname}/" "${path}"
              hub add "${path}"
            fi
}

for package in $(seq 0 "${COUNT}"); do 
    pname="$(./yq r manifest.yaml "packages[${package}].name")"
    defaultref="master"
    pref="$(./yq r manifest.yaml "packages[${package}].ref")"
    pref="${pref:-$defaultref}"
    path="$(./yq r manifest.yaml "packages[${package}].path")"
    prelease="$(./yq r manifest.yaml "packages[${package}].release")"
    prelease="${prelease:=platform}"
    defaultpath="structs/${pname}"
    path="${path:-$defaultpath}"
    render_package "${pname}" "${pref}" "${path}" "${prelease}"
done

sudo rm -rf temp/

if hub commit -m "Vendor dependencies"; then
  hub remote set-url origin "https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
  hub push origin "HEAD:${GITHUB_HEAD_REF}"
else
  echo "no changes for commit"
fi
