local percentErrs(metric, errSelectors) = '100 * sum(rate(%(metric)s{%(errSelectors)s}[1m])) by (instance, job, namespace) / sum(rate(%(metric)s[1m])) by (instance, job, namespace)' % {
  metric: metric,
  errSelectors: errSelectors,
};

local percentErrsWithTotal(metric_errs, metric_total) = '100 * sum(rate(%(metric_errs)s[1m])) by (instance, job, namespace) / sum(rate(%(metric_total)s[1m])) by (instance, job, namespace)' % {
  metric_errs: metric_errs,
  metric_total: metric_total,
};

{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'kafka_alerts',
        rules: [{
          alert: 'KafkaRunningOutOfSpace',
          expr: 'kubelet_volume_stats_available_bytes{pod_name=~"([a-z]+-)+kafka-[0-9]+"} < 5368709120',
          'for': '10s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                There are only {{ $value }} bytes available at {{ $labels.persistentvolumeclaim }} PVC
           |||,
          },
        }, {
          alert: 'UnderReplicatedPartitions',
          expr: 'kafka_server_replicamanager_underreplicatedpartitions > 0',
          'for': '10s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                There are {{ $value }} under replicated partitions on {{ $labels.pod_name }}
           |||,
          },
        }, {
          alert: 'AbnormalControllerState',
          expr: 'sum(kafka_controller_kafkacontroller_activecontrollercount) != 1',
          'for': '10s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                There are {{ $value }} active controllers in the cluster
            |||,
          },
        }, {
          alert: 'OfflinePartitions',
          expr: 'sum(kafka_controller_kafkacontroller_offlinepartitionscount) > 0',
          'for': '10s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                One or more partitions have no leader
            |||,
          },
        }, {
          alert: 'UnderMinIsrPartitionCount',
          expr: 'kafka_server_replicamanager_underminisrpartitioncount > 0',
          'for': '10s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                There are {{ $value }} partitions under the min ISR on {{ $labels.pod_name }}
            |||,
          },
        }, {
          alert: 'OfflineLogDirectoryCount',
          expr: 'kafka_log_logmanager_offlinelogdirectorycount > 0',
          'for': '10s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                There are {{ $value }} offline log directories on {{ $labels.pod_name }}
            |||,
          },
        }, {
          alert: 'ScrapeProblem',
          expr: 'up{job="kubernetes-services",kubernetes_namespace!~"openshift-.+",pod_name=~".+-kafka-[0-9]+"} == 0',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                Prometheus was unable to scrape metrics from {{ $labels.pod_name }}/{{ $labels.instance }} for more than 3 minutes
            |||,
          },
        }, {
          alert: 'ClusterOperatorContainerDown',
          expr: 'count((container_last_seen{container_name="strimzi-cluster-operator"} > (time() - 90))) < 1 or absent(container_last_seen{container_name="strimzi-cluster-operator"})',
          'for': '1m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                The Cluster Operator has been down for longer than 60 seconds
            |||,
          },
        }, {
          alert: 'KafkaBrokerContainersDown',
          expr: 'absent(container_last_seen{container_name="kafka",pod_name=~".+-kafka-[0-9]+"})',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                All `kafka` containers have been down or in CrashLookBackOff status for 3 minutes
            |||,
          },
        }, {
          alert: 'KafkaTlsSidecarContainersDown',
          expr: 'absent(container_last_seen{container_name="tls-sidecar",pod_name=~".+-kafka-[0-9]+"})',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                All `tls-sidecar` containers in the Kafka pods are down or in CrashLookBackOff status for 3 minutes
            |||,
          },
        }, {
          alert: 'KafkaContainerRestartedInTheLast5Minutes',
          expr: 'count(count_over_time(container_last_seen{container_name="kafka"}[5m])) > 2 * count(container_last_seen{container_name="kafka",pod_name=~".+-kafka-[0-9]+"})',
          'for': '5m',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                One or more Kafka containers were restarted too often within the last 5 minutes
            |||,
          },
        }, 
        ],
      },
      {
        name: 'zookeeper_alerts',
        rules: [{
          alert: 'AvgRequestLatency',
          expr: 'zookeeper_avgrequestlatency > 10',
          'for': '10s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
               The average request latency is {{ $value }} on {{ $labels.pod_name }} 
            |||,
          },
        }, {
          alert: 'OutstandingRequests',
          expr: 'zookeeper_outstandingrequests > 10',
          'for': '10s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                There are {{ $value }} outstanding requests on {{ $labels.pod_name }}
            |||,
          },
        }, {
          alert: 'ZookeeperRunningOutOfSpace',
          expr: 'kubelet_volume_stats_available_bytes{pod_name=~"([a-z]+-)+zookeeper-[0-9]+"} < 5368709120',
          'for': '10s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                There are only {{ $value }} bytes available at {{ $labels.persistentvolumeclaim }} PVC
            |||,
          },
        }, {
          alert: 'ZookeeperContainerRestartedInTheLast5Minutes',
          expr: 'count(count_over_time(container_last_seen{container_name="zookeeper"}[5m])) > 2 * count(container_last_seen{container_name="zookeeper",pod_name=~".+-zookeeper-[0-9]+"})',
          'for': '5m',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                One or more Zookeeper containers were restarted too often within the last 5 minutes. This alert can be ignored when the Zookeeper cluster is scaling up
            |||,
          },
        }, {
          alert: 'ZookeeperContainersDown',
          expr: 'absent(container_last_seen{container_name="zookeeper",pod_name=~".+-zookeeper-[0-9]+"})',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                All `zookeeper` containers in the Zookeeper pods have been down or in CrashLookBackOff status for 3 minutes
            |||,
          },
        }, {
          alert: 'ZookeeperTlsSidecarContainersDown',
          expr: 'absent(container_last_seen{container_name="tls-sidecar",pod_name=~".+-zookeeper-[0-9]+"})',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                All `tls-sidecar` containers in the Zookeeper pods have been down or in CrashLookBackOff status for 3 minutes
            |||,
          },
        }, 
      ],
      },
      {
        name: 'entityOperator_alerts',
        rules: [{
          alert: 'TopicOperatorContainerDown',
          expr: 'absent(container_last_seen{container_name="topic-operator",pod_name=~".+-entity-operator-.+"})',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                Container topic-operator in Entity Operator pod has been down or in CrashLookBackOff status for 3 minutes
            |||,
          },
        },{
          alert: 'UserOperatorContainerDown',
          expr: 'absent(container_last_seen{container_name="user-operator",pod_name=~".+-entity-operator-.+"})',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                Container user-operator in Entity Operator pod have been down or in CrashLookBackOff status for 3 minutes
            |||,
          },
        },{
          alert: 'EntityOperatorTlsSidecarContainerDown',
          expr: 'absent(container_last_seen{container_name="tls-sidecar",pod_name=~".+-entity-operator-.+"})',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                Container tls-sidecar in Entity Operator pod have been down or in CrashLookBackOff status for 3 minutes
            |||,
          },
        },
      ],
      },
      {
        name: 'connect_alerts',
        rules: [{
          alert: 'ConnectContainersDown',
          expr: 'absent(container_last_seen{container_name=~".+-connect",pod_name=~".+-connect-.+"})',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                All Kafka Connect containers have been down or in CrashLookBackOff status for 3 minutes
            |||,
          },
    },
    ],
    },
      {
        name: 'bridge_alerts',
        rules: [{
          alert: 'BridgeContainersDown',
          expr: 'absent(container_last_seen{container_name=~".+-bridge",pod_name=~".+-bridge-.+"})',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                All Kafka Bridge containers have been down or in CrashLookBackOff status for 3 minutes
            |||,
          },
    },
    ],
    },
      {
        name: 'mirrormaker_alerts',
        rules: [{
          alert: 'MirrorMakerContainerDown',
          expr: 'absent(container_last_seen{container_name=~".+-mirror-maker",pod_name=~".+-mirror-maker-.+"})',
          'for': '3m',
          labels: {
            severity: 'major',
          },
          annotations: {
            message: |||
                All Kafka Mirror Maker containers have been down or in CrashLookBackOff status for 3 minutes
            |||,
          },
    }
    ],
    },
      {
        name: 'kafkaExporter_alerts',
        rules: [{
          alert: 'UnderReplicatedPartition',
          expr: 'kafka_topic_partition_under_replicated_partition > 0',
          'for': '60s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                Topic {{ $labels.topic }} has {{ $value }} under-replicated partition {{ $labels.partition }}
            |||,
          },
    },{
          alert: 'TooLargeConsumerGroupLag',
          expr: 'kafka_consumergroup_lag > 1000',
          'for': '60s',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                Consumer group {{ $labels.consumergroup}} lag is too big ({{ $value }}) on topic {{ $labels.topic }}/partition {{ $labels.partition }}
            |||,
          },
    },{
          alert: 'NoMessageForTooLong',
          expr: 'changes(kafka_topic_partition_current_offset{topic!="__consumer_offsets"}[30m]) == 0',
          'for': '30m',
          labels: {
            severity: 'warning',
          },
          annotations: {
            message: |||
                There have been no messages in topic {{ $labels.topic}}/partition {{ $labels.partition }} for 10 minutes
          |||,
          },
    },
    ],
    },
    ],
  },
}
