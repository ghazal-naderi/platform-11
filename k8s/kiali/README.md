# kiali
Version: `1.27.0` from [here](https://github.com/kiali/helm-charts)

## requirements
- `istio`
- `prometheus`
- `jaeger`

## installation
Install as any other struct. 

For external access, you need to add an `Ingress` and `Certificate`. Eg.

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx-external
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    cert-manager.io/acme-challenge-type: http01
    nginx.ingress.kubernetes.io/auth-signin: https://auth.sandbox.11fs-structs.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri
    nginx.ingress.kubernetes.io/auth-url: https://auth.sandbox.11fs-structs.com/oauth2/auth
  name: kiali
  namespace: kiali
spec:
  rules:
  - host: kiali.sandbox.11fs-structs.com
    http:
      paths:
      - backend:
          serviceName: kiali
          servicePort: 20001
        path: /
  tls:
  - hosts:
    - kiali.sandbox.11fs-structs.com
    secretName: cert-auth-kiali
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: cert-auth-kiali
  namespace: kiali
spec:
  secretName: cert-auth-kiali
  dnsNames:
    - kiali.sandbox.11fs-structs.com
  commonName: kiali.sandbox.11fs-structs.com
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
```
