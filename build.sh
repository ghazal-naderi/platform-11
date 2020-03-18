#!/bin/bash
LINT="${LINT:=yes}"
set -eu -o pipefail

# Start checks
echo "-- Beginning checks"
[ -d pkg ] && rm -r pkg/
mkdir -p pkg/
find . -iname build.sh -exec ash -c "shellcheck -C -a {} && echo \"✅ {}: Build script passes\"" \; -exec ash -c "[[ \"$0\" != \"{}\" ]] && \"{}\"" \;

for folder in k8s/*/; do
    cwd="$(pwd)"
    file_name="${folder//\//_}"
    file_name_clean="${file_name%?}"
    if [ -d "${folder}/chart" ]; then
        echo "INFO: Detected ${file_name_clean} as containing a Helm chart"
        helm template "${folder}/chart" >> "pkg/${file_name_clean}.yaml" && echo "✅ ${file_name_clean}: k8s Helm passes"
        echo "---" >> "pkg/${file_name_clean}.yaml"
    fi
    if [ -f "${folder}/kustomization.yaml" ]; then
        echo "INFO: Detected ${file_name_clean} as containing Kustomize"
        # Generate k8s YAML for future parsing
        kubectl kustomize "${folder}" >> "pkg/${file_name_clean}.yaml" && echo "✅ ${file_name_clean}: k8s Kustomize passes"
    fi
    if [[ "${LINT}" == 'yes' ]]; then
      # KubEval check - we need to use git directly as @garethr hasn't updated the site yet
      kubeval -v "${KUBERNETES_VERSION#?}" --ignore-missing-schemas -s "https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/" "pkg/${file_name_clean}.yaml" && echo "✅ ${file_name_clean}: k8s kubeval passes"
      # Kube-score checks - we need to ignore the securityContext test as we're not using SELinux. We may add more to this.s
      kube-score score --ignore-test container-security-context "pkg/${file_name_clean}.yaml" && echo "✅ ${file_name_clean}: k8s kube-score passes"
    fi
done

# tflint and terraform checks
for folder in terraform/*/; do
    cwd="$(pwd)"
    if [[ "${LINT}" == 'yes' ]]; then
    (cd "${folder}" && terraform init -backend=false && terraform validate) && echo "✅ terraform validate ${folder} passes"
      tflint "${folder}" && echo "✅ terraform tflint ${folder} passes"
      tfsec "${folder}" && echo "✅ terraform tfsec ${folder} passes"
    fi
    mkdir -p "pkg/${folder}"
    cp -r "${cwd}/${folder}"* "pkg/${folder}"
done

echo "✅ pkg/ wrapped and verified"
# -- finished checks
