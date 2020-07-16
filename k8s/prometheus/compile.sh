#!/usr/bin/env bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifests/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to start with a clean 'manifests' dir
rm -rf manifests
mkdir -p manifests/setup

jsonnet -J vendor -m manifests "${1-example.jsonnet}" | \
    xargs -I"{}" sh -c '(cat "{}" | gojsontoyaml > "{}.yaml") && rm -f "{}"' -- "{}"

setup_manifests=($(find manifests/setup -type f -d 1))
manifests=($(find manifests -type f -d 1))

echo '---
resources:
- addons/fluentd-logging.yaml' > kustomization.yaml
for m in "${setup_manifests[@]}"; do
    [[ "${m}" =~ .yaml ]] && echo "- ${m}" >> kustomization.yaml
done
for m in "${manifests[@]}"; do
    [[ "${m}" =~ .yaml ]] && echo "- ${m}" >> kustomization.yaml
done
