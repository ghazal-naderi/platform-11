#!/usr/bin/env bash
set -e
set -o pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ECK_ROOT="$(dirname "${DIR}")"
kubectl apply -f "${ECK_ROOT}/k8s/custom-resources.yaml"