# ECK struct
`operator.yaml`: version: `1.8.0` from [elastic.co](https://download.elastic.co/downloads/eck/1.8.0/operator.yaml)
`crds.yaml`: version: `1.8.0` from [elastic.co](https://download.elastic.co/downloads/eck/1.8.0/crds.yaml)

## Setup
This includes a user/role for `jaeger` struct.

For Kibana, use Kustomize to add the resources, changing values as appropriate:
```
---
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana
  namespace: eck
spec:
  version: 7.14.2
  count: 1
  elasticsearchRef:
    name: elasticsearch
  http:
    tls:
      certificate:
        secretName: kibana-tls-secret
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kibana
  namespace: eck
  annotations:
    kubernetes.io/ingress.class: "nginx-external"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/affinity: "cookie"
spec:
  tls:
    - hosts:
        - kibana.example.com
      secretName: kibana-tls-secret
  rules:
    - host: kibana.example.com
      http:
        paths:
          - path: /
            backend:
              serviceName: kb-http
              servicePort: 5601

---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: kibana
  namespace: eck
spec:
  secretName: kibana-tls-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: kibana.example.com
  dnsNames:
    - kibana.example.com
```
