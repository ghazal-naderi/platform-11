# prometheus-blackbox
The prometheus blackbox exporter enables active monitoring of internal/external endpoints - eg. external dependencies, VPN endpoints or other services. 
## Requirements
`prometheus`

## Installation
- Ensure that you are using the latest `prometheus` struct that includes additional configuration to monitor `Probe`s.
- Create a `Probe` for each collection of services you want to monitor, using the `test-probe` as an example. Note that this will attempt to resolve and GET google.com by default over SSL.
- To raise alerts on failure, create an alerting rule as follows with customization as appropriate:
```
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRules 
metadata:
  name: prometheus-blackbox-exporter
  labels:
    prometheus: k8s
    role: alert-rules
spec:
  groups:
  - interval: 30s
    name: blackbox.rules
    rules:
    - alert: ProbeFailed
      expr: probe_success == 0
      for: 5m
      labels:
        severity: error
      annotations:
        summary: "Probe failed (instance {{ $labels.instance }})"
        description: "Probe failed\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
    - alert: SlowProbe
      expr: avg_over_time(probe_duration_seconds[1m]) > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Slow probe (instance {{ $labels.instance }})"
        description: "Blackbox probe took more than 1s to complete\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
    - alert: HttpStatusCode
      expr: probe_http_status_code <= 199 OR probe_http_status_code >= 400
      for: 5m
      labels:
        severity: error
      annotations:
        summary: "HTTP Status Code (instance {{ $labels.instance }})"
        description: "HTTP status code is not 200-399\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
    - alert: SslCertificateWillExpireSoon
      expr: probe_ssl_earliest_cert_expiry - time() < 86400 * 30
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "SSL certificate will expire soon (instance {{ $labels.instance }})"
        description: "SSL certificate expires in 30 days\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
    - alert: SslCertificateHasExpired
      expr: probe_ssl_earliest_cert_expiry - time()  <= 0
      for: 5m
      labels:
        severity: error
      annotations:
        summary: "SSL certificate has expired (instance {{ $labels.instance }})"
        description: "SSL certificate has expired already\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
    - alert: HttpSlowRequests
      expr: avg_over_time(probe_http_duration_seconds[1m]) > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "HTTP slow requests (instance {{ $labels.instance }})"
        description: "HTTP request took more than 1s\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
    - alert: SlowPing
      expr: avg_over_time(probe_icmp_duration_seconds[1m]) > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Slow ping (instance {{ $labels.instance }})"
        description: "Blackbox ping took more than 1s\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
    - alert: K8sAPIServerSSLCertExpiringAfterThreeMonths
      expr: probe_ssl_earliest_cert_expiry{job="monitoring/test-probe"} - time() < 86400 * 90 
      for: 1w
      labels:
        severity: warning
      annotations:
        summary: "Kubernetes API Server SSL certificate will expire after three months (instance {{ $labels.instance }})"
        description: "Kubernetes API Server SSL certificate expires in 90 days\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
```
