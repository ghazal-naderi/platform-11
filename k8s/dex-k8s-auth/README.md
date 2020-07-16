# dex-k8s-auth
`dex-k8s-authenticator` from [mintel/dex-k8s-authenticator@92ed659](https://github.com/mintel/dex-k8s-authenticator/tree/92ed659/charts)

requires `dex-rbac`


1. Override the default `Ingress` for `dex-k8s-auth` 
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx-external
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    cert-manager.io/acme-challenge-type: http01
  labels:
    app: dex-k8s-authenticator
    chart: dex-k8s-authenticator-1.2.0
    env: prod
    heritage: Helm
    release: platform
  name: platform-dex-k8s-authenticator
  namespace: dex-k8s-auth
spec:
  rules:
  - host: login.fakebank.example.com
    http:
      paths:
      - backend:
          serviceName: platform-dex-k8s-authenticator
          servicePort: 5555
        path: /
  tls:
  - hosts:
    - login.fakebank.example.com
    secretName: cert-auth-login
```
2. Override the `ConfigMap`, replacing `k8s_ca_pem` with the certificate used for `dex-rbac` and the `client_secret` with the random secret you generated for the same.
```
apiVersion: v1
data:
  config.yaml: |-
    listen: http://0.0.0.0:5555
    web_path_prefix: /
    debug: false
    clusters:
    - client_id: dex-k8s-authenticator
      client_secret: abcdef 
      description: MyCluster Long Description...
      issuer: https://dex.fakebank.example.com
      k8s_ca_pem: "-----BEGIN CERTIFICATE-----\n,,,\n-----END CERTIFICATE----"
      k8s_master_uri: https://fakebank.example.com
      name: fakebank.example.com
      redirect_uri: https://login.fakebank.example.com/callback/my-cluster
      short_description: FakeBank Cluster
kind: ConfigMap
metadata:
  labels:
    app: platform-dex-k8s-authenticator
    chart: dex-k8s-authenticator-1.2.0
    env: prod
    heritage: Helm
    release: platform
  name: platform-dex-k8s-authenticator
  namespace: dex-k8s-auth
```
3. Add a certificate for the `Ingress`
```
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: cert-auth-login
  namespace: dex-k8s-auth
spec:
  secretName: cert-auth-login
  dnsNames:
    - login.fakebank.example.com
  commonName: login.fakebank.example.com
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
```
4. Apply with `kustomize` and confirm functionality with commands from `dex-rbac`
