#!/bin/bash
helm template "k8s/external-secrets/chart" > "k8s/external-secrets/external-secrets.yaml"
