# consul
Official Hashicorp Consul `v0.20.1` helm chart from https://github.com/hashicorp/consul-helm/archive/v0.20.1.zip. `values.yaml` is customized for a standard installation to be used with `vault` on any cloud platform with >`3` nodes.

- Create keys
```
# this example is for a simple dev CA, ideally you'll want to use a real one
# need to use EC prime256v1 because Consul doesn't support RSA or other EC algos.
openssl ecparam -name prime256v1 -genkey -noout -out consulCA.key
openssl req -x509 -new -nodes -key consulCA.key -sha256 -days 4096 -out consulCA.crt
```

- Install `consul` with `brew install consul`
- Create Gossip encryption key
```
# now create a secretsmanager secret that you will install via ExternalSecrets
# it should be of format `key=$(consul keygen)`, replacing `$(consul keygen)` with that command's output
cat <<EOF >> externalsecrets.yaml
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: consul-gossip-encryption-key
  namespace: consul
secretDescriptor:
  backendType: secretsManager
  dataFrom:
    - consul-gossip-encryption-key-dev
EOF
```
- Create CA certificate secrets 
```
# create a secret for ca certificates with format `tls.crt=$(cat consul.dev.crt)`
# also, a secret for ca key with format `tls.key=$(cat consul.dev.key)`
# being sure to replace the `$()` values with the output of those commands
cat <<EOF >> externalsecrets.yaml
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: consul-ca-cert
  namespace: consul
secretDescriptor:
  backendType: secretsManager
  data:
  - key: consul-ca-cert-dev
    name: key
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: consul-ca-key
  namespace: consul
secretDescriptor:
  backendType: secretsManager
  data:
  - key: consul-ca-key-dev
    name: key
EOF```
```
- requires `stable` storageclass using the appropriate cloud storage provisioner (example for AWS):
---
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: stable
provisioner: kubernetes.io/aws-ebs 
reclaimPolicy: Retain
parameters:
    fsType: ext4
    type: gp2
allowVolumeExpansion: true
volumeBindingMode: Immediate
```

## troubleshooting/administration
try:
```
k run --rm -it -n consul --env="CONSUL_HTTP_TOKEN=$(k get secret -n consul platform-consul-bootstrap-acl-token -o 'go-template={{ index .data "token"}}' | base64 -D)" --env='CONSUL_HTTP_SSL_VERIFY=false' --env='CONSUL_LOCAL_CONFIG={"leave_on_terminate": true}' --env='CONSUL_HTTP_ADDR=platform-consul-server-0.platform-consul-server.consul.svc:8501' --env='CONSUL_HTTP_SSL=true' --image consul test-consul -- ash
consul members
consul --help
```
