#!/usr/bin/env bash
set -e
set -o pipefail

K8S_DIR="./structs-k8s/gen6/${CLUSTER_NAME}"

kubectl apply -k "${K8S_DIR}"

# After deploy we need to export the cert and user credential secrets into kube-system for use by other services
kubectl -n eck get secret eck-es-http-certs-public --export -o yaml | kubectl apply -n=kube-system -f -
kubectl -n eck get secret eck-es-elastic-user --export -o yaml | kubectl apply -n=kube-system -f -

# We use the values in the es secrets to cause a rollingdeploy of fluentd if changed.
CERT=$(kubectl -n eck get secret "eck-es-http-certs-public" -o go-template='{{index .data "tls.crt"}}')
PW=$(kubectl -n eck get secret "eck-es-elastic-user" -o go-template='{{.data.elastic}}')
ES_SECRET_HASH=($( echo -n ${CERT}${PW} | md5sum))

# Restart fluentd. Ideally we only need to restart if the password has changed from the original.
# We can do this by causing a rolling update via adding a content hash label for cert and user secrets.
kubectl -n kube-system label daemonset fluentd esSecretHash=${ES_SECRET_HASH} --overwrite
