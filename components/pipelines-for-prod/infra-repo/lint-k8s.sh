#!/usr/bin/env bash
mkdir ~/bin
curl -Lo /tmp/kubeval.tgz "https://github.com/instrumenta/kubeval/releases/download/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz" 
tar -C /tmp/ -xf /tmp/kubeval.tgz
mv /tmp/kubeval ~/bin/kubeval
chmod +x ~/bin/kubeval
curl -Lo ~/bin/kubescore "https://github.com/zegl/kube-score/releases/download/v${KUBESCORE_VERSION}/kube-score_${KUBESCORE_VERSION}_linux_amd64"
chmod +x ~/bin/kubescore
cd k8s || exit 127
export PATH="$HOME/bin:$PATH"
ENVIRONMENTS=($(find . -maxdepth 1 -type d -not -path ./base -not -path ./apps -not -path .))
for e in "${ENVIRONMENTS[@]}"; do
  cd "${e}" || exit 127
  if kustomize build . > "${e}.yaml"; then
    echo "✅ ${e}: k8s kustomize passes"
  else
    echo "❌: ${e}: k8s kustomize failed"
    exit 127
  fi
  if kubeval -v "${KUBERNETES_VERSION#?}" --ignore-missing-schemas "${e}.yaml"; then
    echo "✅ ${e}: k8s kubeval passes"
  else
    echo "❌: ${e}: k8s kubeval failed"
    exit 127
  fi
  if kubescore score --ignore-test container-security-context "${e}.yaml"; then
    echo "✅ ${e}: k8s kubescore passes"
  else
    echo "❌: ${e}: k8s kubescore failed"
  fi
  cd .. || exit 127
done
