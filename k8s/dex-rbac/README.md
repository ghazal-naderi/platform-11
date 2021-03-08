# dex-rbac
`dex` from [mintel/dex-k8s-authenticator@92ed659](https://github.com/mintel/dex-k8s-authenticator/tree/92ed659/charts)

1. Create a Github app at at `dex.fakebank.example.com`.
2. Retrieve your Kubernetes parent keys
```
sudo cat /srv/kubernetes/ca.{crt,key}
-----BEGIN CERTIFICATE-----
,,,,
-----END CERTIFICATE-----
-----BEGIN RSA PRIVATE KEY-----
,,,,
-----END RSA PRIVATE KEY-----
```
3. Replace the Secret content with the key and certificate content from step 2.
```
---
# Source: dex/templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: dex-rbac-tls
  labels:
    app: dex-rbac
    env: prod
    chart: "dex-1.2.0"
    release: "dex-rbac"
    heritage: "Helm"
type: kubernetes.io/tls
data:
    tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCiAuLi4KIC0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ==
    tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQouLi4KLS0tLS1FTkQgUlNBIFBSSVZBVEUgS0VZLS0tLS0=
```
4. Override the `ClusterRoleBinding` for readonly access with your own Github `org:team`. Override `ConfigMap` in client repository, replacing `fakebank.example.com` with your own URL. Replace the config's `clientID` and `clientSecret` for Github with those obtained in step 1. Change the `sharedSecret` to a randomly generated value also applied to `dex-k8s-authenticator`'s `ConfigMap`. This is also the time to add any additional `ClusterRoleBinding`s for other orgs/teams.
```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: dex-cluster-auth
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-readonly
subjects:
  - kind: Group
    name: "fake-org:Fake Team"
---
apiVersion: v1
data:
  config.yaml: |-
    issuer: https://dex.fakebank.example.com
    storage:
      type: kubernetes
      config:
        inCluster: true
    web:
      https: 0.0.0.0:5556
      tlsCert: /etc/dex/tls/tls.crt
      tlsKey: /etc/dex/tls/tls.key
    frontend:
      theme: "coreos"
      issuer: "Example Co"
      issuerUrl: "https://example.com"
      logoUrl: https://example.com/images/logo-250x25.png
    expiry:
      signingKeys: "6h"
      idTokens: "24h"
    logger:
      level: debug
      format: json
    oauth2:
      responseTypes: ["code", "token", "id_token"]
      skipApprovalScreen: true
    connectors:
    - type: github
      id: github
      name: GitHub
      config:
        clientID: fffffff 
        clientSecret: fbfbfbfbfbfbfbfb 
        redirectURI: https://dex.fakebank.example.com/callback
        orgs:
        - name: fake-org 
    staticClients:
    - id: dex-k8s-authenticator
      name: "dex-k8s-authenticator"
      secret: "abcdef"
      redirectURIs:
      - https://login.fakebank.example.com/callback/my-cluster
    enablePasswordDB: False
    staticPasswords: []
kind: ConfigMap
metadata:
  labels:
    app: platform-dex
    chart: dex-1.2.0
    env: prod
    heritage: Helm
    release: platform
  name: platform-dex
  namespace: dex-rbac
---
```
5. Add an ingress for `dex`
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx-external
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
  labels:
    app: platform-dex
    chart: dex-1.2.0
    env: prod
    heritage: Helm
    release: platform
  name: platform-dex-rbac
  namespace: dex-rbac
spec:
  rules:
  - host: dex.fakebank.example.com
    http:
      paths:
      - backend:
          serviceName: platform-dex
          servicePort: 5556
        path: /
  tls:
  - hosts:
    - dex.fakebank.example.com
    secretName: cert-auth-dex
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: cert-auth-dex
  namespace: dex-rbac
spec:
  secretName: cert-auth-dex
  dnsNames:
    - dex.fakebank.example.com
  commonName: dex.fakebank.example.com
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
```
6. Add configuration to Kops
```
# kops edit cluster
  kubeAPIServer:
    anonymousAuth: false
    authorizationMode: RBAC
    oidcClientID: dex-k8s-authenticator
    oidcGroupsClaim: groups
    oidcIssuerURL: https://dex.fakebank.example.com
    oidcUsernameClaim: email
# kops update cluster --yes
# kops rolling-update cluster --yes
```
7. Deploy & test Dex with `curl -sI https://dex.k8s.example.com/callback | head -1`, response should be `HTTP/2 400`
8. Deploy & test `dex-k8s-auth` struct according to it's documentation, use `curl -sI https://login.k8s.example.com/ | head -1` and ensure `HTTP/2 200` response
