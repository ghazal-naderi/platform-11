# References
Most of our structs are very close to upstream and support a lot of customization and configuration. Below is a list of documentation that will help build an understanding of the features of each technology. To challenge the use of a technology, propose an alternative or raise questions in an 11:FS platform context please use GitHub issues raised against this repository (11FSConsulting/platform).

## Infrastructure
- Base infrastructure management via [Terraform](https://www.terraform.io/docs/index.html)

## Kubernetes Cluster
- Cluster creation using [Kops](https://kops.sigs.k8s.io/)
- Networking via [Cilium](https://docs.cilium.io/en/v1.8/)
- DNS via [CoreDNS](https://coredns.io/manual/toc/)

## Cluster Utilities
- Certificate automation via [cert-manager](https://cert-manager.io/docs/)
- Secret management via [external-secrets[(https://github.com/godaddy/kubernetes-external-secrets)
- DNS management via [external-dns](https://github.com/kubernetes-sigs/external-dns)
- Ingress management via [ingress-nginx](https://kubernetes.github.io/ingress-nginx/)
- Cluster-local secret storage (eg. where no cloud option available) via [Vault](https://www.vaultproject.io/docs) backing onto [Consul](https://www.consul.io/docs)
- Authentication via GitHub using [oauth2_proxy](https://github.com/oauth2-proxy/oauth2-proxy)
- Automatic replacement of deployments on secrets changes via [reloader](https://github.com/stakater/Reloader)

## Authentication
- RBAC via GitHub using [dex](https://dexidp.io/docs/kubernetes/) fronted by [dex-k8s-authenticator](https://github.com/mintel/dex-k8s-authenticator)

## Service Mesh
- Meshing via [Istio](https://istio.io/latest/docs/)
- Visualization via [Kiali](https://kiali.io/documentation/latest/features/)

## CI/CD
- Cluster-internal CI/CD (Kubernetes and Terraform) via [Tekton Pipelines](https://github.com/tektoncd/pipeline) and [Tekton Triggers](https://github.com/tektoncd/triggers)
- Cluster-external CI/CD (applications and pre-deploy linting/validation) via [GitHub Actions](https://docs.github.com/en/free-pro-team@latest/actions)

## Databases/Storage
- [PostgreSQL](https://www.postgresql.org/docs/) in AWS via [AWS Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html)
- [PostgreSQL](https://www.postgresql.org/docs/) in GCP via [Google Cloud SQL](https://cloud.google.com/sql/docs)
- Cluster-local [PostgreSQL](https://www.postgresql.org/docs/) via [postgres-operator](https://github.com/zalando/postgres-operator)
- Cluster-local S3-compatible object storage via [Minio](https://docs.min.io/docs/minio-bucket-versioning-guide.html)
- PostgreSQL databases/usernames/passwords on AWS/GCP platforms abstracted via [movetokube/postgres-operator](https://github.com/movetokube/postgres-operator/tree/0.4.2) for development environments

## Artifacts
- [Nexus Repository Manager 3](https://help.sonatype.com/repomanager3) for development artifact storage and caching (eg. Maven artifacts)

## Messaging
- [Kafka](https://kafka.apache.org/documentation/) via [Strimzi Kafka Operator](https://strimzi.io/docs/operators/latest/overview.html) and [Confluent Schema Registry](https://docs.confluent.io/current/schema-registry/index.html)

## Observability
- Graphing/charting/dashboarding via [Grafana](https://grafana.com/docs/grafana/latest/explore/)
- Metrics monitoring via [Prometheus](https://prometheus.io/docs/introduction/overview/)
- Distributed tracing via [Jaeger](https://www.jaegertracing.io/docs/1.20/) backed onto [Elasticsearch via ECK](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-overview.html)
- Logging via [Loki](https://grafana.com/docs/loki/latest/) and [logging-operator](https://banzaicloud.com/docs/one-eye/logging-operator/crds/)
