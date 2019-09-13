#!/usr/bin/env bash
set -e
set -o pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ECK_ROOT="$(dirname $(dirname "${DIR}"))"
kubectl apply -k "${ECK_ROOT}/k8s"

# After deploy we need to export the cert and user credential secrets into kube-system for use by other services
kubectl -n elasticstack get secret elasticsearch-es-http-certs-public --export -o yaml | kubectl apply -n=kube-system -f -
kubectl -n elasticstack get secret elasticsearch-es-elastic-user --export -o yaml | kubectl apply -n=kube-system -f -
