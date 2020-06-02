local jaegerAlerts = (import 'jaeger-mixin/alerts.libsonnet').prometheusAlerts;
local kafkaAlerts = (import 'kafka-alerts.libsonnet').prometheusAlerts;
local elasticsearchAlerts = (import 'elasticsearch-alerts.libsonnet').prometheusAlerts;
local jaegerDashboard = (import 'jaeger-mixin/mixin.libsonnet').grafanaDashboards;
local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  // TODO:
  // (import 'kube-prometheus/kube-prometheus-kops.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-kops-coredns.libsonnet') +
  // or
  // (import 'kube-prometheus/kube-prometheus-kube-aws.libsonnet')
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-managed-cluster.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-node-ports.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-static-etcd.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-thanos-sidecar.libsonnet') +
  {
    _config+:: {
      namespace: 'monitoring',
      prometheus+:: {
        namespaces+: ['jaeger', 'kafka', 'eck', 'tekton-pipelines', 'external-dns', 'ingress-nginx', 'cert-manager', 'auth', 'elastic-system'],
      },
      alertmanager+: {
        config: (importstr 'alertmanager.config.yaml'),
      },
      grafana+:: {
        config: { // http://docs.grafana.org/installation/configuration/
          sections: {
            server+: {
              root_url: 'http://grafana.example.com/',
            },
            "auth.anonymous": {enabled: true, org_role: "Admin"}, # we will control auth via auth struct
          },
        },
      },
    },
    prometheus+:: {
        prometheus+: {
            spec+: {
                externalUrl: 'http://prometheus.example.com',
            },
        },
        serviceMonitorJaeger: {
          apiVersion: 'monitoring.coreos.com/v1',
          kind: 'ServiceMonitor',
          metadata: {
            name: 'jaeger',
            namespace: 'jaeger',
          },
          spec: {
            jobLabel: 'job',
            endpoints: [
              {
                port: 'http-metrics',
              },
            ],
            selector: {
              matchLabels: {
                name: 'jaeger-operator',
              },
            },
          },
        },
        serviceMonitorElasticsearch: {
          apiVersion: 'monitoring.coreos.com/v1',
          kind: 'ServiceMonitor',
          metadata: {
            name: 'eck',
            namespace: 'eck',
          },
          spec: {
            jobLabel: 'job',
            endpoints: [
              {
                port: 'http',
              },
            ],
            selector: {
              matchLabels: {
                app: 'elasticsearch-exporter',
              },
            },
          },
        },
        serviceMonitorKafka: {
        apiVersion: 'monitoring.coreos.com/v1',
        kind: 'ServiceMonitor',
        metadata: {
          name: 'kafka',
          namespace: 'kafka',
        },
        spec: {
          jobLabel: 'job',
          endpoints: [
            {
              port: 'prometheus',
            },
          ],
          selector: {
            matchLabels: {
              'strimzi.io/name': 'cluster-kafka-exporter',
            },
          },
        },
      },
    },
    rawGrafanaDashboards+:: {
      'kafka.json': (importstr 'kafka.json'),
      'elasticsearch-logs.json': (importstr 'elasticsearch-logs.json'),
    },
    grafanaDashboards+:: {
      'jaeger.json': jaegerDashboard['jaeger.json'],
    },
    prometheusAlerts+:: jaegerAlerts + kafkaAlerts + elasticsearchAlerts, 
    alertmanager+:: {
        alertmanager+: {
            spec+: {
                externalUrl: 'http://alertmanager.example.com',
            },
        },
    },
} + {
  prometheusAlerts+:: {
    groups: std.map(
      function(group)
        if group.name == 'kubernetes-resources' then
          group {
            rules: std.map(
              function(rule)
                if rule.alert == "CPUThrottlingHigh" then
                  rule {
                    expr: |||
              sum(increase(container_cpu_cfs_throttled_periods_total{container!=""}[5m])) by (container, pod, namespace)
                /
              sum(increase(container_cpu_cfs_periods_total[5m])) by (container, pod, namespace)
                > ( 95 / 100 )
             |||
                  }
                else
                  rule,
                group.rules
            )
          }
        else
          group,
      super.groups
    ),
  },
};


{ ['setup/0namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor is separated so that it can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
