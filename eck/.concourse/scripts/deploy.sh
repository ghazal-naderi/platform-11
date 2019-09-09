#!/usr/bin/env bash
set -e
set -o pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ECK_ROOT="$(dirname $(dirname "${DIR}"))"
kubectl apply -k "${ECK_ROOT}/k8s"