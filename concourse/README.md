## Concourse

This is a vendored Helm chart which we apply via helm template and then Kustomize. It does not require Tiller installed on the cluster.

The use of kustomize allows us to add additional resources and expose all default resources created by the chart for modification.