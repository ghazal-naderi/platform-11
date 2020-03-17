#!/bin/bash
set -eu -o pipefail
# Updates here
kubernetes_version="v1.17.4"
terraform_version="0.12.23"
helm_version="v3.1.2"
shellcheck_version="v0.7.0"
tflint_version="v0.15.2"
tfsec_version="v0.19.0"
kubeval_version="0.14.0"
kubescore_version="1.5.1"

# purely for testing
export AWS_DEFAULT_REGION=eu-west-1
export AWS_REGION=eu-west-1

# Obtain dependencies
echo "-- Obtaining dependencies"
os=$(uname | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
mkdir -p temp bin
# shell/check
curl -sL "https://github.com/koalaman/shellcheck/releases/download/${shellcheck_version}/shellcheck-${shellcheck_version}.${os}.${arch}.tar.xz" -o temp/shellcheck.tar.xz
tar -C temp/ -xf temp/shellcheck.tar.xz
mv temp/shellcheck-${shellcheck_version}/shellcheck bin/shellcheck 
# dirty but it works for the rest
if [[ "${arch}" == "x86_64" ]]; then
    arch="amd64"
fi
# tflint
curl -sL "https://github.com/terraform-linters/tflint/releases/download/${tflint_version}/tflint_${os}_${arch}.zip" -o temp/tflint.zip
unzip -q -d temp/ temp/tflint.zip
mv temp/tflint bin/tflint
# tfsec
curl -sL "https://github.com/liamg/tfsec/releases/download/${tfsec_version}/tfsec-${os}-${arch}" -o bin/tfsec
# helm
curl -sL "https://get.helm.sh/helm-${helm_version}-${os}-${arch}.tar.gz" -o temp/helm.tgz
tar -C temp/ -xf temp/helm.tgz
mv "temp/${os}-${arch}/helm" bin/helm
# kubeval
curl -sL "https://github.com/instrumenta/kubeval/releases/download/${kubeval_version}/kubeval-${os}-${arch}.tar.gz" -o temp/kubeval.tgz
tar -C temp/ -xf temp/kubeval.tgz
mv temp/kubeval bin/kubeval
# kube-score
curl -sL "https://github.com/zegl/kube-score/releases/download/v${kubescore_version}/kube-score_${kubescore_version}_${os}_${arch}" -o bin/kube-score
# terraform
curl -sL "https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_${os}_${arch}.zip" -o temp/terraform.zip
unzip -q -d temp/ temp/terraform.zip 
mv temp/terraform bin/terraform
# kubectl
curl -sL "https://dl.k8s.io/${kubernetes_version}/kubernetes-client-${os}-${arch}.tar.gz" -o temp/kubectl.tgz
tar -C temp/ -xf temp/kubectl.tgz
mv temp/kubernetes/client/bin/kubectl bin/kubectl
rm -r temp/
chmod +x bin/*
# -- finished obtaining dependencies

# Start checks
echo "-- Beginning checks"
mkdir -p pkg/
# Build script
bin/shellcheck -C -a build.sh && echo "✅ Build script passes"

# Generate k8s YAML for future parsing
bin/kubectl kustomize k8s > pkg/k8s.yaml && echo "✅ k8s Kustomize passes"

# KubEval check - we need to use git directly as @garethr hasn't updated the site yet
bin/kubeval -v "${kubernetes_version#?}" --ignore-missing-schemas -s https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/ pkg/k8s.yaml && echo "✅ k8s kubeval passes"

# Kube-score checks - we need to ignore the securityContext test as we're not using SELinux. We may add more to this.s
bin/kube-score score --ignore-test container-security-context pkg/k8s.yaml && echo "✅ k8s kube-score passes"

# tflint and terraform checks
for folder in terraform/*/; do
    cwd="$(pwd)"
    (cd "${folder}" && "${cwd}/bin/terraform" init -backend=false && terraform validate) && echo "✅ terraform validate ${folder} passes"
    bin/tflint "${folder}" && echo "✅ terraform tflint ${folder} passes"
    bin/tfsec "${folder}" && echo "✅ terraform tfsec ${folder} passes"
    mkdir -p "pkg/${folder}"
    cp -r "${cwd}/${folder}"* "pkg/${folder}"
done

echo "✅ pkg/ wrapped and verified"
unset AWS_DEFAULT_REGION
unset AWS_REGION
# -- finished checks
