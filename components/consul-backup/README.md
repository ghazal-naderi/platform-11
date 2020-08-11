This docker container allows the backing up of consul to an S3 compatible storage backend.

This container is intended for use as a cronjob for example.

```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: consul-backup
  namespace: consul
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          imagePullSecrets:
            - name: ocirsecret
          containers:
          - name: consul-backup
            image: jed.ocir.io/fr9ckauowgwh/consul-backup:0.3
            envFrom:
            - secretRef:
                name: consul-backup-secret
            env:
            - name: CONSUL_HTTP_SSL_VERIFY
              value: "true"
            - name: CONSUL_HTTP_SSL
              value: "true"
            - name: FORCE_PATH_STYLE
              value: "true"
            - name: BACKUP_BUCKET
              value: "consul-prod-backup"
            - name: ENDPOINT_URL
              value: "https://fr9ckauowgwh.compat.objectstorage.me-jeddah-1.oraclecloud.com"
            - name: HTTP_ADDR
              value: "https://platform-consul-server:8501"
            - name: AWS_REGION
              value: "me-jeddah-1"
          restartPolicy: OnFailure
```
