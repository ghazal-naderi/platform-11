# Prometheus

Version `v0.3.0` from (coreos/kube-prometheus)[https://github.com/coreos/kube-prometheus/tree/v0.3.0]

## install
- Apply the struct to conduct basic setup of CRDs and some services
- Apply the struct once again to intialize the basic Prometheus, AlertManager, etc
- Create AlertManager and Grafana config secrets, replacing the `INSERT_SLACK_WEBHOOK_URL_HERE` and `url:` with your own Slack webhook and external URL (base64 decode this and replace as appropriate). Likewise, update the Prometheus and Alertmanager resources with your own `externalUrl` via Kustomize `patchesStrategicMerge`:
```
---
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: k8s
  namespace: monitoring
spec:
  externalUrl: http://prometheus.mino-dev.enva.gen6bk.com
---
apiVersion: monitoring.coreos.com/v1
kind: Alertmanager
metadata:
  name: main
  namespace: monitoring
spec:
  externalUrl: http://alertmanager.mino-dev.enva.gen6bk.com
---
apiVersion: v1
kind: Secret
metadata:
  name: grafana-config
  namespace: monitoring
data:
  grafana.ini: W2F1dGguYW5vbnltb3VzXQplbmFibGVkID0gdHJ1ZQpvcmdfcm9sZSA9IEFkbWluCltzZXJ2ZXJdCnJvb3RfdXJsID0gaHR0cDovL2dyYWZhbmEubWluby1kZXYuZW52YS5nZW42YmsuY29tLwo= 
---
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-main
  namespace: monitoring
data:
  alertmanager.yaml: Z2xvYmFsOgogIHJlc29sdmVfdGltZW91dDogNW0KICBzbGFja19hcGlfdXJsOiAnSU5TRVJUX1NMQUNLX1dFQkhPT0tfVVJMX0hFUkUnCnJvdXRlOgogIGdyb3VwX2J5OiBbJ2FsZXJ0bmFtZScsICdhcHAnLCAnam9iJ10KICBncm91cF93YWl0OiAzMHMKICBncm91cF9pbnRlcnZhbDogNW0KICByZXBlYXRfaW50ZXJ2YWw6IDFoCiAgcmVjZWl2ZXI6ICdzbGFjay1ub3RpZmljYXRpb25zJwogIHJvdXRlczoKICAtIG1hdGNoOgogICAgICBhbGVydG5hbWU6IFdhdGNoZG9nCiAgICByZWNlaXZlcjogJ251bGwnCiAgLSBtYXRjaDoKICAgICAgc2V2ZXJpdHk6IGNyaXRpY2FsCiAgICByZWNlaXZlcjogJ3NsYWNrLW5vdGlmaWNhdGlvbnMnCmluaGliaXRfcnVsZXM6CiAgLSBzb3VyY2VfbWF0Y2g6CiAgICAgIHNldmVyaXR5OiAnY3JpdGljYWwnCiAgICB0YXJnZXRfbWF0Y2g6CiAgICAgIHNldmVyaXR5OiAnd2FybmluZycKICAgIGVxdWFsOiBbJ2FsZXJ0bmFtZScsICdhcHAnLCAnam9iJ10KcmVjZWl2ZXJzOgotIG5hbWU6ICdudWxsJwotIG5hbWU6ICdzbGFjay1ub3RpZmljYXRpb25zJwogIHNsYWNrX2NvbmZpZ3M6CiAgLSBjaGFubmVsOiAnc2xhY2stbm90aWZpY2F0aW9ucy10ZXN0JwogICAgc2VuZF9yZXNvbHZlZDogdHJ1ZQogICAgY29sb3I6ICd7eyBpZiBlcSAuU3RhdHVzICJmaXJpbmciIH19ZGFuZ2Vye3sgZWxzZSB9fWdvb2R7eyBlbmQgfX0nCiAgICB0aXRsZTogJ1t7eyAuU3RhdHVzIHwgdG9VcHBlciB9fXt7IGlmIGVxIC5TdGF0dXMgImZpcmluZyIgfX06e3sgLkFsZXJ0cy5GaXJpbmcgfCBsZW4gfX17eyBlbmQgfX1dIFByb21ldGhldXMgRXZlbnQgTm90aWZpY2F0aW9uJwogICAgcHJldGV4dDogJ3t7IC5Db21tb25Bbm5vdGF0aW9ucy5zdW1tYXJ5IH19JwogICAgdGV4dDogfC0KICAgICAgIHt7IHJhbmdlIC5BbGVydHMgfX0KICAgICAgICAge3stIGlmIC5Bbm5vdGF0aW9ucy5zdW1tYXJ5IH19KkFsZXJ0Oioge3sgLkFubm90YXRpb25zLnN1bW1hcnkgfX0gLSBge3sgLkxhYmVscy5zZXZlcml0eSB9fWB7ey0gZW5kIH19CiAgICAgICAgICpEZXNjcmlwdGlvbjoqIHt7IC5Bbm5vdGF0aW9ucy5kZXNjcmlwdGlvbiB9fXt7IC5Bbm5vdGF0aW9ucy5tZXNzYWdlIH19CiAgICAgICAgICpHcmFwaDoqIDx7eyAuR2VuZXJhdG9yVVJMIH19fDpjaGFydF93aXRoX3Vwd2FyZHNfdHJlbmQ6Pnt7IGlmIG9yIC5Bbm5vdGF0aW9ucy5ydW5ib29rIC5Bbm5vdGF0aW9ucy5ydW5ib29rX3VybCB9fSAqUnVuYm9vazoqIDxodHRwczovL2dpdGh1Yi5jb20vMTFGU0NvbnN1bHRpbmcvcGxhdGZvcm0vdHJlZS9tYXN0ZXIvZG9jcy9BTEVSVFMubWQje3sgLkxhYmVscy5hbGVydG5hbWUgfX18OnNwaXJhbF9ub3RlX3BhZDo+e3sgZW5kIH19CiAgICAgICAgICpEZXRhaWxzOioKICAgICAgICAge3sgcmFuZ2UgLkxhYmVscy5Tb3J0ZWRQYWlycyB9fSAtICp7eyAuTmFtZSB9fToqIGB7eyAuVmFsdWUgfX1gCiAgICAgICAgIHt7IGVuZCB9fQogICAgICAge3sgZW5kIH19Cg==

```
- Create ingresses for each of the services as below
```
---
apiVersion: extensions/v1beta1 
kind: Ingress
metadata:
  name: grafana
  namespace: monitoring
  annotations:
    kubernetes.io/tls-acme: "true"
    certmanager.k8s.io/cluster-issuer: "letsencrypt-prod"
    certmanager.k8s.io/acme-challenge-type: http01
    kubernetes.io/ingress.class: nginx-external
    nginx.ingress.kubernetes.io/auth-url: "https://auth.example.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://auth.example.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri"
spec:
  tls:
  - hosts:
    - grafana.example.com
    secretName: grafana-tls
  rules:
  - host: grafana.example.com
    http:
      paths:
      - path: /avatar/ # https://grafana.com/blog/2020/06/03/grafana-6.7.4-and-7.0.2-released-with-important-security-fix/
        backend:
          serviceName: does-not-exist
          servicePort: 80
      - path: /
        backend:
          serviceName: grafana
          servicePort: 3000
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: grafana
  namespace: monitoring
spec:
  secretName: grafana-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: grafana.example.com
  dnsNames:
    - grafana.example.com
---
apiVersion: extensions/v1beta1 
kind: Ingress
metadata:
  name: prometheus
  namespace: monitoring
  annotations:
    kubernetes.io/tls-acme: "true"
    certmanager.k8s.io/cluster-issuer: "letsencrypt-prod"
    certmanager.k8s.io/acme-challenge-type: http01
    kubernetes.io/ingress.class: nginx-external
    nginx.ingress.kubernetes.io/auth-url: "https://auth.example.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://auth.example.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri"
spec:
  tls:
  - hosts:
    - prometheus.example.com
    secretName: prometheus-tls
  rules:
  - host: prometheus.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: prometheus-k8s
          servicePort: 9090
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: prometheus
  namespace: monitoring
spec:
  secretName: prometheus-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: prometheus.example.com
  dnsNames:
    - prometheus.example.com
---
apiVersion: extensions/v1beta1 
kind: Ingress
metadata:
  name: alertmanager
  namespace: monitoring
  annotations:
    kubernetes.io/tls-acme: "true"
    certmanager.k8s.io/cluster-issuer: "letsencrypt-prod"
    certmanager.k8s.io/acme-challenge-type: http01
    kubernetes.io/ingress.class: nginx-external
    nginx.ingress.kubernetes.io/auth-url: "https://auth.example.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://auth.example.com/oauth2/start?rd=https%3A%2F%2F$host$request_uri"
spec:
  tls:
  - hosts:
    - alertmanager.example.com
    secretName: alertmanager-tls
  rules:
  - host: alertmanager.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: alertmanager-main
          servicePort: 9093
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: alertmanager
  namespace: monitoring
spec:
  secretName: alertmanager-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: alertmanager.example.com
  dnsNames:
    - alertmanager.example.com
```
- If using `fluentd` for logging, apply `addons/fluentd-logging.yaml` into your own cluster
## notes
- In order to allow Prometheus to monitor all namespaces, kustomize the `ClusterRole` as follows:
```
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-k8s
rules:
- apiGroups:
  - ""
  resources:
  - nodes/metrics
  verbs:
  - get
- nonResourceURLs:
  - /metrics
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - services
  - pods
  - endpoints
  verbs:
  - get
  - list
  - watch
``` 
## contributing 
- Get `jsonnet-bundler` and `gojsontoyaml`
```
GO111MODULE="on" go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
go get github.com/brancz/gojsontoyaml
```
- Use `compile.sh prometheus.jsonnet` to compile the base struct from `prometheus.jsonnet` 
