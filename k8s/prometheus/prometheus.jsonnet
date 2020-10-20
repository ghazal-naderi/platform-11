local utils = import 'mixin-utils/utils.libsonnet';
local jaegerAlerts = (import 'github.com/jaegertracing/jaeger/monitoring/jaeger-mixin/alerts.libsonnet').prometheusAlerts;
local lokiAlerts = (import 'github.com/grafana/loki/production/loki-mixin/alerts.libsonnet').prometheusAlerts;
local kafkaAlerts = (import 'kafka-alerts.libsonnet').prometheusAlerts;
local elasticsearchAlerts = (import 'elasticsearch-alerts.libsonnet').prometheusAlerts;
local lokiAlerts = (import 'github.com/grafana/loki/production/loki-mixin/mixin.libsonnet').prometheusAlerts;
local jaegerDashboard = (import 'github.com/jaegertracing/jaeger/monitoring/jaeger-mixin/mixin.libsonnet').grafanaDashboards;
local lokiDashboard = (import 'github.com/grafana/loki/production/loki-mixin/mixin.libsonnet') { showMultiCluster:: false, matchers:: [utils.selector.eq('job', 'platform-loki-headless')], }.grafanaDashboards;
local lokiRules = (import 'github.com/grafana/loki/production/loki-mixin/mixin.libsonnet').prometheusRules;

local kp =
  (import 'github.com/coreos/kube-prometheus/jsonnet/kube-prometheus/kube-prometheus.libsonnet') +
  (import 'github.com/coreos/kube-prometheus/jsonnet/kube-prometheus/kube-prometheus-kops.libsonnet') +
  (import 'github.com/coreos/kube-prometheus/jsonnet/kube-prometheus/kube-prometheus-kops-coredns.libsonnet') +
  // or
  // (import 'github.com/coreos/kube-prometheus/jsonnet/kube-prometheus/kube-prometheus-kube-aws.libsonnet')
  // Uncomment the following imports to enable its patches
  // (import 'github.com/coreos/kube-prometheus/jsonnet/kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
  // (import 'github.com/coreos/kube-prometheus/jsonnet/kube-prometheus/kube-prometheus-managed-cluster.libsonnet') +
  // (import 'github.com/coreos/kube-prometheus/jsonnet/kube-prometheus/kube-prometheus-node-ports.libsonnet') +
  // (import 'github.com/coreos/kube-prometheus/jsonnet/kube-prometheus/kube-prometheus-static-etcd.libsonnet') +
  // (import 'github.com/coreos/kube-prometheus/jsonnet/kube-prometheus/kube-prometheus-thanos-sidecar.libsonnet') +
  {
    _config+:: {
      namespace: 'monitoring',
      prometheus+:: {
        namespaces+: ['jaeger', 'kafka', 'loki', 'logging-operator', 'eck', 'tekton-pipelines', 'external-dns', 'ingress-nginx', 'cert-manager', 'auth' ],
      },
      alertmanager+: {
        config: (importstr 'alertmanager.config.yaml'),
      },
      grafana+:: {
        datasources+: [{
          name: 'loki',
          type: 'loki',
          access: 'proxy',
          org_id: 1,
          url: 'http://platform-loki.loki.svc.cluster.local:3100',
          version: 1,
          uid: 'lokids',
          editable: false,
          jsonData: {
            maxLines: 5000,
            derivedFields: [
            {
                "datasourceUid": "jaegerds",
                "matcherRegex": 'traceId":"(.+)","spanId"',
                "name": "traceId",
                "url": "$${__value.raw}",
            },
            {
                "datasourceUid": "jaegerds",
                "matcherRegex": '"parentId":"(.+)"',
                "name": "parentId",
                "url": "$${__value.raw}",
            },
            ],
          },
        },
        {
          name: 'jaeger',
          type: 'jaeger',
          uid: 'jaegerds',
          access: 'proxy',
          org_id: 1,
          url: 'http://stream-query.jaeger.svc.cluster.local:16686',
          version: 1,
          editable: false,
        },],
        // FIXME: Loki dashboards below are strangely integrated as they are too large to import normally
        rawDashboards+:: {
          'kafka.json': (importstr 'kafka.json'),
          'loki-operational.json': (importstr 'vendor/github.com/grafana/loki/production/loki-mixin/dashboards/dashboard-loki-operational.json'),
          'loki-logs.json': (importstr 'vendor/github.com/grafana/loki/production/loki-mixin/dashboards/dashboard-loki-logs.json'),
        },
        config: { // http://docs.grafana.org/installation/configuration/
          sections: {
            server+: {
              root_url: 'http://grafana.example.com/',
            },
            "auth.anonymous": {enabled: true, org_role: "Admin"}, # we will control auth via auth struct
          },
        },
      },
      versions+:: {
        grafana: '7.1.0',
      },
    },
    prometheus+:: {
        prometheus+: {
            spec+: {
                externalUrl: 'http://prometheus.example.com',
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
              port: 'tcp-prometheus',
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
    grafanaDashboards+:: jaegerDashboard + { 'loki-writes.json': lokiDashboard['loki-writes.json'], 'loki-reads.json': lokiDashboard['loki-reads.json'], 'loki-chunks.json': lokiDashboard['loki-chunks.json'], },
    prometheusAlerts+:: jaegerAlerts + elasticsearchAlerts + kafkaAlerts + lokiAlerts,
    prometheusRules+:: lokiRules,
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
          if group.name == 'kubernetes-system-apiserver' || group.name == 'kubernetes-system-controller-manager' || group.name == 'kubernetes-system-scheduler' || group.name == 'prometheus' then
             group {
               rules: std.filter(
                 function(rule)
                   rule.alert != 'AggregatedAPIDown' && rule.alert != 'KubeControllerManagerDown' && rule.alert != 'KubeSchedulerDown' && rule.alert != 'PrometheusDuplicateTimestamps',
                 group.rules
               ),
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
