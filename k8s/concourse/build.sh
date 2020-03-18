#!/bin/bash
helm template "k8s/concourse/chart" > "k8s/concourse/concourse.yaml"
