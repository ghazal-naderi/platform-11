#!/usr/bin/env bash
lint(){
  if (cd "${1}" && terraform init -input=false -backend=false && terraform validate); then
      echo "✅ terraform inits and validates"
  else
      echo "❌ terraform does not init or validate"
      exit 127
  fi
  if tflint "${1}"; then
     echo "✅ tflint validates"
  else
     echo "❌ tflint does not validate"
     exit 127
  fi
  if tfsec "${1}"; then
     echo "✅ tfsec validates"
  else
     echo "❌ tfsec does not validate, continuing..."
  fi
}
mkdir ~/bin
curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -Lo /tmp/terraform.zip && unzip -q -d /tmp/ /tmp/terraform.zip && mv /tmp/terraform ~/bin/terraform && chmod +x ~/bin/terraform
curl "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip" -Lo /tmp/tflint.zip && unzip -q -d /tmp/ /tmp/tflint.zip && mv /tmp/tflint ~/bin/tflint && chmod +x ~/bin/tflint
curl "https://github.com/liamg/tfsec/releases/download/${TFSEC_VERSION}/tfsec-linux-amd64" -Lo ~/bin/tfsec && chmod +x ~/bin/tfsec
cd terraform || exit 127
export PATH="$HOME/bin:$PATH"
cd structs || exit 127
STRUCTS=($(find . maxdepth 1 -type d -not -path .))
for s in "${STRUCTS[@]}"; do
    lint "${s}"
done
cd .. || exit 127
ENVIRONMENTS=($(find . -maxdepth 1 -type d -not -path ./structs -not -path ./app-provisioning -not -path .))
for e in "${ENVIRONMENTS[@]}"; do
    lint "${e}"
done
