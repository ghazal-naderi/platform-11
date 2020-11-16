# 11:FS consultancy FusionAuth
This is a struct for the Fusion Auth self hosted appliance: https://fusionauth.io

## Dependencies
A database for it to be pointed at.

## Usage
This is designed to be used in the structs fashion used in other consultancy projects; I.e., not used directly. Instead, a Kustomize setup should use this as it's base and overlay required config.

What it doesn't do is configure FusionAuth, that's still a manual job. Once deployed, someone has to log onto the admin panel and setup users etc. 

An example usage would look like this:

```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx-external
  labels:
    app: fusionauth
  name: fusionauth
  namespace: fusionauth
spec:
  rules:
  - host: fusionauth.stage.oci.11fs-structs.com
    http:
      paths:
      - backend:
          serviceName: fusionauth
          servicePort: 9011
        path: /
  tls:
  - hosts:
    - fusionauth.stage.oci.11fs-structs.com
    secretName: fusionauth-11fs-structs-tls

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fusionauth
  namespace: fusionauth
spec:
  replicas: 3
  
---
apiVersion: v1
kind: Secret
metadata:
  name: fusionauth
  namespace: fusionauth
type: Opaque
data:
  DB_PASSWORD: asdhjaljkasldjaskljdaiouoiuaiosudasd==
  DB_USER: lsdfksdkfljsdf
```
##Secret Configuration
A secret needs tobe added as part of the configuration, e.g.

apiVersion: v1
kind: Secret
metadata:
  name: fusionauth
  namespace: fusionauth
type: Opaque
data:
  DB_PASSWORD: REPLACE_THE_PASSWORD
  DB_USER: REPLACE_THE_USER


That's about enough over-rides to get it up and running
