# fluentd
From [fluent/fluentd-kubernetes-daemonset](https://github.com/fluent/fluentd-kubernetes-daemonset/blob/master/fluentd-daemonset-elasticsearch-rbac.yaml)

## Setup
This struct requires you to copy ECK secrets from the `eck` namespace into the `kube-system` namespace:

```
k get secret -n eck elasticsearch-es-https-certs-public --export -o yaml | kubectl apply -n kube-system -f -
k get secret -n eck elasticsearch-es-http-certs-public --export -o yaml | kubectl apply -n kube-system -f -
```
