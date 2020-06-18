# 11:FS consultancy FusionAuth
This is a struct for the Fusion Auth self hosted appliance: https://fusionauth.io

## Dependencies
This base has a dependency on the Crunchy Data Postgres operator: https://github.com/CrunchyData/postgres-operator This operator needs to be deployed and functional prior to deploying this config. If not, you'll have some wildly interesting error messages as Kube tries to create resources it knows nothing about. This only leads to a truculent Kube cluster that needs to be coaxed out with soothing words and offers of sweeties. 

## Usage
This is designed to be used in the structs fashion used in other consultancy projects; I.e., not used directly. Instead, a Kustomize setup should use this as it's base and overlay required config.

On first run, this config will:
    - Create a PostGres DB
    - Deploy the application
    - Create the database

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

That's about enough over-rides to get it up and running
