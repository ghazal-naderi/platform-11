# sonatype-nexus
From [Oteemo/charts/sonatype-nexus](https://github.com/Oteemo/charts/tree/master/charts/sonatype-nexus) at [ec795d](https://github.com/Oteemo/charts/commit/ec795d2d485a92d7a6fc3c7847c45808f4c75f80)

Configuration documentation at [travelaudience/kubernetes-nexus](https://github.com/travelaudience/kubernetes-nexus). 

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
