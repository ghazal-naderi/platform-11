# logging-operator
Requires `loki`
## S3
- Create the bucket and add node policy via `kops`, examples are in `terraform/aws-s3-logs`
- Add ClusterOutput as below
```
apiVersion: logging.banzaicloud.io/v1beta1
kind: ClusterOutput
metadata:
  name: s3-output
  namespace: logging-operator
spec:
 s3:
   instance_profile_credentials: {}
   s3_bucket: structs-sandbox-logs
   s3_region: eu-west-2
   path: logs/${tag}/%Y/%m/%d/
   buffer:
     timekey: 1m
     timekey_wait: 10s
     timekey_use_utc: true
```
- Customize the ClusterFlow in order to add the new output
```
apiVersion: logging.banzaicloud.io/v1beta1
kind: ClusterFlow
metadata:
  name: loki-flow
  namespace: logging-operator
spec:
  match:
    - select: {}
  filters:
    - tag_normaliser: {}
    - parser:
        key_name: message
        reserve_time: true
        reserve_data: true
        remove_key_name_field: true
        inject_key_prefix: log_
        parse:
          type: json
  outputRefs:
    - loki-output
    - s3-output
``` 
