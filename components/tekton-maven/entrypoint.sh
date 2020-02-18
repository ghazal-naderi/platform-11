#!/bin/bash

# Start dockerd in background
nohup dockerd > /var/log/docker.log 2>&1 &

exec "$@"
