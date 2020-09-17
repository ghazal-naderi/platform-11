# Jaeger
## install
- In preparation, make sure that the `eck` and `kafka` structs are installed
- Apply this struct to create the initial `namespace` and `operator` - it won't create the `Jaeger` until you apply it for a second time
- Note that the ECK certificate secret will be automatically synchronized to the `jaeger` namespace with a `CronJob`, with special adjustments as per [ECK requirements](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-common-problems.html#k8s-common-problems-owner-refs).
- Create `jaeger` user secret
```
cat <<EOF >> jaeger-secrets.yaml
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: jaeger-es-secret 
  namespace: jaeger
secretDescriptor:
  backendType: secretsManager
  dataFrom:
    - jaeger-es-secret-dev 
EOF
k apply -f jaeger-secrets.yaml
```

or

```
kubectl create secret -n jaeger generic jaeger-secret --from-literal=ES_PASSWORD=changeme --from-literal=ES_USERNAME=jaeger
```
- Create the `jaeger` user in ECK
```
# k exec -it -n eck elasticsearch-es-default-0 -- sh
< within the container >
# bin/elasticsearch-users useradd jaeger -p <password> -r jaeger
# cat config/users
< copy the user:hash line into the secret below, replacing the jaeger user:hash >
```

```
---
kind: Secret
apiVersion: v1
metadata:
  name: filerealm-jaeger
  namespace: eck
stringData:
  users: |-
    jaeger:$2a$10$.QZzI9a2ov2QjnUmZ3N9SOxHRe.CKWBuLHGIp7.CPaTVwI62GZ9Fy
  users_roles: |-
    jaeger:jaeger
```

- Create ingress for the UI if it should be exposed. Example uses `auth` and `cert-manager` structs
```
---
apiVersion: extensions/v1beta1 
kind: Ingress
metadata:
  name: jaeger-ui
  namespace: jaeger
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
    - jaeger.example.com
    secretName: jaeger-ui-tls
  rules:
  - host: jaeger.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: stream-query
          servicePort: 16686

---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: jaeger
  namespace: jaeger
spec:
  secretName: jaeger-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: jaeger.example.com
  dnsNames:
    - jaeger.example.com
```
- Make any customizations via overlay of the `jaeger.yaml` via `kustomize`
- Apply this struct a second time to initialize the `Jaeger` CRD

## configuration
- Instrument client applications with the [client libraries](https://www.jaegertracing.io/docs/1.17/client-libraries/).
- Add the annotation `"sidecar.jaegertracing.io/inject": "true"` to your application `Deployment`s
