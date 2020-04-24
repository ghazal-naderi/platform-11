# postgres-operator
This is version 0.4.2 of [movetokube/postgres-operator](https://github.com/movetokube/postgres-operator/tree/0.4.2). It manages postgres databases and users automatically. 

**Do not create database resources for databases that already exist and were created manually!**

So far, it supports `AWS` and `Azure`:

1. Create an (optionally `ExternalSecret`-managed) `Secret` with the following content, replacing the obvious username/password/host/etc:
```
  POSTGRES_HOST: "mydatabase"
  POSTGRES_USER: "admin"
  POSTGRES_PASS: "thepassword"
  POSTGRES_URI_ARGS: ""
  POSTGRES_CLOUD_PROVIDER: "AWS"
  POSTGRES_DEFAULT_DATABASE: "postgres"
``` 
2. Add your own `secret.yaml`, getting `dataFrom` to point to your own secret (eg. `example-db-admin-dboperator`)
```
apiVersion: v1
kind: ExternalSecret
metadata:
  name: ext-postgres-operator
  namespace: postgres-operator
type: Opaque
dataFrom:
- example-db-admin-dboperator
```
3. Apply this `kustomize` file.

## Example CRDs:
```
apiVersion: db.movetokube.com/v1alpha1
kind: Postgres
metadata:
  name: my-db
  namespace: app
spec:
  database: test-db # Name of database created in PostgreSQL
  dropOnDelete: false # Set to true if you want the operator to drop the database and role when this CR is deleted (optional)
  masterRole: test-db-group (optional)
  schemas: # List of schemas the operator should create in database (optional)
  - stores
  - customers
  extensions: # List of extensions that should be created in the database (optional)
  - fuzzystrmatch
  - pgcrypto
```

```
apiVersion: db.movetokube.com/v1alpha1
kind: PostgresUser
metadata:
  name: my-db-user
  namespace: app
spec:
  role: username
  database: my-db # This references the Postgres CR
  secretName: my-secret
  privileges: OWNER # Can be OWNER/READ/WRITE
```
