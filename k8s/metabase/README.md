# metabase
## requirements
None, though `auth`, `ingress-nginx` and `cert-manager` are required for `Ingress` and `Certificate` with authentication.
## introduction
Metabase is a business intelligence and visualization tool allowing business users to drive insights from application databases
## installation
Simply include the struct and add a `Certificate`/`Ingress` to your environment.

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx-external
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    cert-manager.io/acme-challenge-type: http01
    nginx.ingress.kubernetes.io/auth-url: "https://auth.sandbox.11fs-structs.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://auth.sandbox.11fs-structs.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri"
  labels:
    app: metabase
    chart: metabase-0.13.0
    release: platform
    heritage: Helm
  name: platform-metabase
  namespace: metabase
spec:
  rules:
  - host: metabase.sandbox.11fs-structs.com 
    http:
      paths:
      - backend:
          serviceName: platform-metabase
          servicePort: 80
        path: /
  tls:
  - hosts:
    - metabase.sandbox.11fs-structs.com
    secretName: cert-auth-metabase
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  labels:
    app: metabase
    chart: metabase-0.13.0
    release: platform
    heritage: Helm
  name: cert-auth-metabase 
  namespace: metabase
spec:
  secretName: cert-auth-metabase
  dnsNames:
    - metabase.sandbox.11fs-structs.com 
  commonName: metabase.sandbox.11fs-structs.com
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
```

Note that all configuration will be lost on restart unless settings are provided to connect to an external database. 

To do so, you'll need to override the environment variables: 

eg.
```
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: platform-metabase
  namespace: metabase
  labels:
    app: metabase
    chart: metabase-0.13.0
    release: platform
    heritage: Helm
spec:
  selector:
    matchLabels:
      app: metabase
  template:
    spec:
      containers:
        - name: metabase
          env:
          - name: MB_DB_TYPE
            value: postgres
          - name: MB_DB_CONNECTION_URI
            valueFrom:
              secretKeyRef:
                name: platform-metabase-database
                key: test-secret-postgres
```

... and add a secret ...

```
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: platform-metabase-database
  namespace: metabase
  labels:
    app: metabase
    chart: metabase-0.13.0
    release: platform
    heritage: Helm
secretDescriptor:
  backendType: secretsManager
  dataFrom:
    - metabase-secret-int
```
(or)
```
---
apiVersion: v1
kind: Secret
metadata:
  name: platform-metabase-database
  namespace: metabase
  labels:
    app: metabase
    chart: metabase-0.13.0
    release: platform
    heritage: Helm
type: Opaque
data:
  connectionURI: "cG9zdGdyZXM6Ly91c2VyOnBhc3N3b3JkQGhvc3Q6cG9ydC9kYXRhYmFzZT9zc2w9dHJ1ZSZzc2xtb2RlPXJlcXVpcmUmc3NsZmFjdG9yeT1vcmcucG9zdGdyZXNxbC5zc2wuTm9uVmFsaWRhdGluZ0ZhY3Rvcnki"
```
