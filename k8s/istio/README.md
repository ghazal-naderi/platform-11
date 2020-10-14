# istio
Version: `1.7.3` from [here](https://storage.googleapis.com/istio-release/releases/1.7.3/istioctl-1.7.3-linux-amd64.tar.gz)/manifests/charts/istio-operator

Addons:
- [Prometheus ServiceMonitor](https://istio.io/latest/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring)
- PrometheusRules from the same place as ServiceMonitor 
- [Prometheus](https://raw.githubusercontent.com/istio/istio/release-1.7/samples/addons/prometheus.yaml)
Dashboards:
- [Istio mesh](https://grafana.com/grafana/dashboards/7639)
- [Istio service](https://grafana.com/grafana/dashboards/7636)
- [Istio workload](https://grafana.com/grafana/dashboards/7630)
- [Istio performance](https://grafana.com/grafana/dashboards/11829)
- [Istio controlplane](https://grafana.com/grafana/dashboards/7645)

## notes
Uses an embedded Prometheus for `kiali`, with federation via `prometheus` struct. 
After an uninstall, certificate secrets remain due to [istio#23706](https://github.com/istio/istio/issues/23706) - remove them manually via `kubectl delete configmap -l istio.io/config=true -A`

## requirements
Requirements are documented in the Terraform structs for new clusters - there are particular settings required on the cluster level in order to support istio.

## installation
Simply include as any other struct. Once installed, create an instance of the `IstioOperator` custom resource as per [documentation](https://istio.io/latest/docs/setup/install/operator/#install) - eg.

```
k create ns istio-system
k apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
EOF
```

This will create an example Istio control plane using the `default` profile.

For dashboards, kustomize the Grafana deployment as below:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: grafana
  name: grafana
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: grafana
  template:
    spec:
      containers:
        - name: grafana
          volumeMounts:
            - mountPath: /grafana-dashboard-definitions/0/istio-control-plane
              name: grafana-dashboard-istio-control-plane
              readOnly: false
            - mountPath: /grafana-dashboard-definitions/0/istio-mesh
              name: grafana-dashboard-mesh
              readOnly: false
            - mountPath: /grafana-dashboard-definitions/0/istio-performance
              name: grafana-dashboard-performance
              readOnly: false
            - mountPath: /grafana-dashboard-definitions/0/istio-service
              name: grafana-dashboard-service
              readOnly: false
            - mountPath: /grafana-dashboard-definitions/0/istio-workload
              name: grafana-dashboard-workload
              readOnly: false
      volumes:
        - configMap:
            name: grafana-dashboard-istio-control-plane
          name: grafana-dashboard-istio-control-plane
        - configMap:
            name: grafana-dashboard-istio-mesh
          name: grafana-dashboard-istio-mesh
        - configMap:
            name: grafana-dashboard-istio-performance
          name: grafana-dashboard-istio-performance
        - configMap:
            name: grafana-dashboard-istio-service
          name: grafana-dashboard-istio-service
        - configMap:
            name: grafana-dashboard-istio-workload
          name: grafana-dashboard-istio-workload
```
