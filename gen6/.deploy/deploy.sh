#!/usr/bin/env bash
set -e
set -o pipefail

K8S_DIR="./structs-k8s/gen6/${CLUSTER_NAME}"

kubectl apply -k "${K8S_DIR}"

# After deploy we need to export the cert and user credential secrets into kube-system for use by other services
kubectl -n eck get secret eck-es-http-certs-public --export -o yaml | kubectl apply -n=kube-system -f -
kubectl -n eck get secret eck-es-elastic-user --export -o yaml | kubectl apply -n=kube-system -f -
