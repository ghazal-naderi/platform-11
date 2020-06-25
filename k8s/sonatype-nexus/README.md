# sonatype-nexus
From [Oteemo/charts/sonatype-nexus](https://github.com/Oteemo/charts/tree/master/charts/sonatype-nexus) at [ec795d](https://github.com/Oteemo/charts/commit/ec795d2d485a92d7a6fc3c7847c45808f4c75f80)

Configuration documentation at [travelaudience/kubernetes-nexus](https://github.com/travelaudience/kubernetes-nexus). 


Nexus needs access to `Secrets` and `ConfigMaps` - you must create the necessary `Role` and `RoleBinding` as follows (assumes default `release` in `manifest.yaml`):
```
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: platform-sonatype-nexus
  namespace: sonatype-nexus
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: platform-sonatype-nexus
  namespace: sonatype-nexus
subjects:
- kind: ServiceAccount
  name: platform-sonatype-nexus
  namespace: sonatype-nexus
roleRef:
  kind: Role
  name: platform-sonatype-nexus
  apiGroup: rbac.authorization.k8s.io
---

```

(*FIXME: The below password change method is broken due to the plugin running in UNKNOWN context, for now you need to change password from `admin123` manually and immediately after deploying*)
In order to set a password, create a `Secret` with name `nexus` and value `password` with the admin password. By default, the password is `admin123`.
Example:
```
---
apiVersion: 'kubernetes-client.io/v1'
kind: ExternalSecret
metadata:
  name: nexus
  namespace: sonatype-nexus 
secretDescriptor:
  backendType: secretsManager
  data:
    - key: nexus-user
      name: password
      property: password
```

This will set the password to the value of `nexus-user -> password` SecretsManager secret.

Be sure to also create an `Ingress` and associated `Certificate`:
```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nexus
  namespace: sonatype-nexus
  annotations:
    kubernetes.io/tls-acme: "true"
    certmanager.k8s.io/cluster-issuer: "letsencrypt-prod"
    certmanager.k8s.io/acme-challenge-type: http01
    kubernetes.io/ingress.class: nginx-external
spec:
  tls:
  - hosts:
    - nexus.sandbox.fakebank.com
    secretName: nexus-tls
  rules:
  - host: nexus.sandbox.fakebank.com
    http:
      paths:
      - path: /
        backend:
          serviceName: platform-sonatype-nexus
          servicePort: 8080
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: nexus
  namespace: sonatype-nexus
spec:
  secretName: nexus-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  commonName: nexus.sandbox.fakebank.com
  dnsNames:
    - nexus.sandbox.fakebank.com
```

## Configuration
- It makes sense to configure Nexus with a `Cleanup Policy` to remove `Pre-release / Snapshot Versions` published before `30` days.
- Create a role, perhaps `developer` with the `Privileges` `nx-repository-view-*-*-edit` and `nx-repository-view-*-*-read`
- Create a user for this role, perhaps `developer` with the role `developer`
- Disallow `anonymous` access
- Add `Tasks` for `Cleanup snapshots` (of type `Meven - Delete Snapshot`) and to `Remote deleted items` (of type `Admin - Compact blob store`) with automatic scheduling for 6am once per day.
