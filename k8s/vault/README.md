# vault
- Create `consul` cluster using `consul` struct (be sure to follow `README.md`!)
- Create Consul policy and key for Vault
```
k run --rm -it -n consul --env="CONSUL_HTTP_TOKEN=$(k get secret -n consul platform-consul-bootstrap-acl-token -o 'go-template={{ index .data "token"}}'| base64 -D)" --env='CONSUL_HTTP_SSL_VERIFY=false' --env='CONSUL_LOCAL_CONFIG={"leave_on_terminate": true}' --env='CONSUL_HTTP_ADDR=platform-consul-server.consul.svc:8501' --env='CONSUL_HTTP_SSL=true' --image consul test-consul -- ash
cat <<EOF>> vault.rules.hcl
{
  "key_prefix": {
    "vault/": {
      "policy": "write"
    }
  },
  "node_prefix": {
    "": {
      "policy": "write"
    }
  },
  "service": {
    "vault": {
      "policy": "write"
    }
  },
  "agent_prefix": {
    "": {
      "policy": "write"
    }
  },
  "session_prefix": {
    "": {
      "policy": "write"
    }
  }
}
EOF
consul acl policy create -name "vault" -description "Policy for Vault" -datacenter "dc" -rules @vault.rules.hcl
consul acl token create -description "Token for Vault" -policy-id "$(consul acl policy read -name vault --format=json | jq -r '.ID')"
```
- Store policy and key (examples for AWS secrets manager)
```
cat <<EOF>> consulsecrets.yaml
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: vault-consul-token
  namespace: vault
secretDescriptor:
  backendType: secretsManager
  dataFrom: 
  - vault-consul-token-dev
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: consul-ca-cert
  namespace: vault
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
  namespace: vault
secretDescriptor:
  backendType: secretsManager
  data:
  - key: consul-ca-key-dev
    name: key
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: vault-ca-cert
  namespace: vault
secretDescriptor:
  backendType: secretsManager
  data:
  - key: vault-ca-cert-dev
    name: key
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: vault-ca-key
  namespace: vault
secretDescriptor:
  backendType: secretsManager
  data:
  - key: vault-ca-key-dev
    name: key
EOF
k apply -f consulsecrets.yaml
```
- To configure automatic (un)sealing, use `kustomize` to patch in additional environment variables to `vault/templates/server-statefulset.yaml` as in the [documentation](https://www.vaultproject.io/docs/configuration/seal/awskms).
- Utilize Vault secrets as `ExternalSecrets` by following the `ExternalSecrets` [documentation](https://github.com/godaddy/kubernetes-external-secrets#hashicorp-vault)
- Istio can be integrated as per the [documentation](https://archive.istio.io/v1.2/docs/tasks/security/vault-ca/)  
