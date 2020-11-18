#!/bin/bash
LINT="${LINT:=yes}"
RELEASE="${RELEASE:=platform}" # safe default
KUBEVAL_API_VERSION="${KUBEVAL_API_VERSION:-1.18.0}"

set -eu -o pipefail

# Start checks
echo "-- Beginning checks"
[ -d pkg ] && rm -r pkg/
mkdir -p pkg/k8s/
find . -iname build.sh -exec ash -c "shellcheck -C -a {} && echo \"✅ {}: Build script passes\"" \; -exec ash -c "[[ \"$0\" != \"{}\" ]] && \"{}\"" \;

for folder in k8s/*/; do
    cwd="$(pwd)"
    file_name="$(echo "${folder}" | cut -d'/' -f2)"
    if [ -d "${folder}/chart" ]; then
        echo "INFO: Detected ${file_name} as containing a Helm chart, rendering..."
        namespace="${file_name}" # safe default
        helm template -n "${namespace}" "${RELEASE}" "${folder}/chart" > "k8s/${file_name}/${file_name}.yaml" && echo "✅ ${file_name}: k8s Helm passes"
    fi
    if [ -f "${folder}/kustomization.yaml" ]; then
        echo "INFO: Detected ${file_name} as containing Kustomize, templating..."
        # Generate k8s YAML for future parsing
        kustomize build "${folder}" > "pkg/k8s/${file_name}.yaml" && echo "✅ ${file_name}: k8s Kustomize passes"
    fi
    if [[ "${LINT}" == 'yes' ]]; then
      echo "INFO: Validating schemas against Kubernetes API: ${KUBEVAL_API_VERSION}"
      kubeval --kubernetes-version "${KUBEVAL_API_VERSION}" --ignore-missing-schemas "pkg/k8s/${file_name}.yaml" && echo "✅ ${file_name}: k8s kubeval passes"
      # Kube-score checks - we need to ignore the securityContext test as we're not using SELinux. We may add more to this.s
      kube-score score --ignore-test container-security-context "pkg/k8s/${file_name}.yaml" && echo "✅ ${file_name}: k8s kube-score passes"
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

# Workflow checks
for folder in workflows/*/; do
   cwd="$(pwd)"
   if [[ "${LINT}" == 'yes' ]]; then
       find "${folder}.github/workflows" -type f -iname \*.yaml -exec ash -c "yq r {} -jel && echo \"✅ {}: passes lint\"" \;
       find "${folder}.github/workflows" -type f -iname \*.sh -exec ash -c "shellcheck -S error {} && echo \"✅ {}: passes lint\"" \;
   fi
   mkdir -p "pkg/${folder}.github/"
   cp -r "${cwd}/${folder}.github/workflows/" "pkg/${folder}.github/workflows/"
done

echo "✅ pkg/ wrapped and verified"
# -- finished checks
