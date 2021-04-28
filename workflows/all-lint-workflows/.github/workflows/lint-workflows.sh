#!/usr/bin/env bash
mkdir ~/bin
curl -Lo ~/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
curl -Lo /tmp/shellcheck.tar.xz "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz"
tar -C /tmp/ -xf /tmp/shellcheck.tar.xz
mv "/tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck" ~/bin/shellcheck
chmod +x ~/bin/shellcheck
chmod +x ~/bin/yq
cd .github/workflows || exit 127
export PATH="$HOME/bin:$PATH"
YAML_FILES=($(find . -maxdepth 1 -type f -iname \*.yaml))
for yaml in "${YAML_FILES[@]}"; do
    if yq eval "${yaml}" -j; then 
      echo "✅ ${yaml}: passes lint"
    else
      echo "❌: ${yaml}: failed lint"
      exit 127
    fi
done
SH_FILES=($(find . -maxdepth 1 -type f -iname \*.sh))
for shell in "${SH_FILES[@]}"; do
    if shellcheck -S error "${shell}"; then 
      echo "✅ ${shell}: passes lint"
    else
      echo "❌: ${shell}: failed lint"
      exit 127
    fi
done
