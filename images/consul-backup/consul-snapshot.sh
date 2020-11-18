#!/usr/bin/env bash

CURRENT_TIME=$(date +"%FT%H%M%S")

echo [default] > ~/.aws/credentials
echo aws_access_key_id = $CONSUL_BUCKET_ACCESS >> ~/.aws/credentials
echo aws_secret_access_key = $CONSUL_BUCKET_SECRET >> ~/.aws/credentials

# consul snapshot save -http-addr=https://docker.for.mac.localhost:8500 ${CURRENT_TIME}.snap
consul snapshot save -http-addr=$HTTP_ADDR /workspace/${CURRENT_TIME}.snap

# aws s3 cp ${CURRENT_TIME}.snap s3://consul-prod-backup/${CURRENT_TIME}.snap --endpoint-url https://fr9ckauowgwh.compat.objectstorage.me-jeddah-1.o
aws s3 cp /workspace/${CURRENT_TIME}.snap s3://${BACKUP_BUCKET}/${CURRENT_TIME}.snap --endpoint-url $ENDPOINT_URL