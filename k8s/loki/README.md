# loki
## requirements
- `logging-operator`
- `jaeger`
## introduction
Loki chart from [grafana/helm-charts/tree/main/charts/loki](https://github.com/grafana/helm-charts/tree/main/charts/loki) at `2.1.0`. Loki ingests logs and provides a means to search them. It integrates with Grafana and logging-operator to provide a rolling view on the last 3 months of logs.

## scaling
In it's default configuration, do not scale Loki past 1 node - you can end up with split brain! In order to scale gracefully, refer to the following pages:
https://grafana.com/docs/loki/latest/operations/storage/
https://grafana.com/docs/loki/latest/configuration/
https://grafana.com/docs/loki/latest/operations/storage/table-manager/
https://grafana.com/docs/loki/latest/operations/storage/retention/

You can use *DynamoDB* with *S3* on AWS, *BigTable* with *GCS* on GCP or *Cassandra* with an *S3-compatible* service on other providers.
