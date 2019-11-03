#!/usr/bin/env bash

ENV_DIR="./structs-k8s/gen6/${CLUSTER_NAME}"

template() {
    helm template \
    -n $1 ./structs-k8s/$1/chart \
    -f ./structs-k8s/$1/values.yaml \
    -f ${ENV_DIR}/$1-values.yaml > ./structs-k8s/$1/$1.yaml
}

shopt -s nullglob
for i in $ENV_DIR/*-values.yaml; do
    filename=$(basename $i)
    item=${filename%"-values.yaml"}
    echo "Found $item. Preparing."
    template $item
done
