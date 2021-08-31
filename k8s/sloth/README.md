# Sloth
[Sloth](https://github.com/slok/sloth) generates Prometheus rules from SLOs for monitoring and alterting.

version `9b8e292bdc059c9fba94d55ad20bc4f3374d3014` from `main`

## installation
Requires `prometheus` struct. This struct can be installed as normal. 

Requires `kustomization` of Grafana like so for the dashboard:
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
          - mountPath: /grafana-dashboard-definitions/0/sloth
            name: grafana-dashboard-sloth
      volumes:
        - configMap:
            name: grafana-dashboard-sloth
          name: grafana-dashboard-sloth
```

## updates
Dashboard is from [here](https://grafana.com/grafana/dashboards/14348), converted into a `ConfigMap`.

```
curl -L https://raw.githubusercontent.com/slok/sloth/main/pkg/kubernetes/gen/crd/sloth.slok.dev_prometheusservicelevels.yaml -o crd/sloth.slok.dev_prometheusservicelevels.yaml
curl -L https://raw.githubusercontent.com/slok/sloth/main/deploy/kubernetes/raw/sloth-with-common-plugins.yaml -o sloth-with-common-plugins.yaml
```

## example
```
version: "prometheus/v1"
service: "myservice"
labels:
  owner: "myteam"
  repo: "myorg/myservice"
  tier: "2"
slos:
  # We allow failing (5xx and 429) 1 request every 1000 requests (99.9%).
  - name: "requests-availability"
    objective: 99.9
    description: "Common SLO based on availability for HTTP request responses."
    labels:
      category: availability
    sli:
      events:
        error_query: sum(rate(http_request_duration_seconds_count{job="myservice",code=~"(5..|429)"}[{{.window}}]))
        total_query: sum(rate(http_request_duration_seconds_count{job="myservice"}[{{.window}}]))
    alerting:
      name: "MyServiceHighErrorRate"
      labels:
        category: "availability"
      annotations:
        # Overwrite default Sloth SLO alert summmary on ticket and page alerts.
        summary: "High error rate on 'myservice' requests responses"
      page_alert:
        labels:
          severity: "pageteam"
          routing_key: "myteam"
      ticket_alert:
        labels:
          severity: "slack"
          slack_channel: "#alerts-myteam"
```
