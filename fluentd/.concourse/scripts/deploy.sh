#!/usr/bin/env bash
set -e
set -o pipefail

# !!!!!!!!! TODO: Just copy the secret from the eck deploy and put it into kube-system !!!!!!!!!!!!!!
# Generate a random password and add along with fluentd user to file elasticsecret.env
# Move/ensure file is located alongisde k8s/kustomization.yaml
# Create new user in elasticsearch or update existing user
#   - is the only option to use the API?
#   - how could we add a user via file auth?

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
FLUENTD_ROOT="$(dirname $(dirname "${DIR}"))"
kubectl apply -k "${FLUENTD_ROOT}/k8s"