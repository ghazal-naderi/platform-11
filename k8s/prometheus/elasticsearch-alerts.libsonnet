{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'elasticsearch_alerts',
        rules: [ 
        {
          "expr": "100 * (elasticsearch_filesystem_data_size_bytes - elasticsearch_filesystem_data_free_bytes / elasticsearch_filesystem_data_size_bytes)",
          "record": "elasticsearch_filesystem_data_used_percent"
        },
        {
          "expr": "100 - elasticsearch_filesystem_data_used_percent",
          "record": "elasticsearch_filesystem_data_free_percent"
        },
        {
          "alert": "ElasticsearchTooFewNodesRunning",
          "annotations": {
            "description": "There are only {{ $value }} < 3 ElasticSearch nodes running",
            "summary": "ElasticSearch running on less than 3 nodes"
          },
          "expr": "elasticsearch_cluster_health_number_of_nodes < 3",
          "for": "5m",
          "labels": {
            "severity": "critical"
          }
        },
        {
          "alert": "ElasticsearchHeapUsageTooHigh",
          "annotations": {
            "description": "The heap usage is over 90% for 5m   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch Heap Usage Too High (instance {{ $labels.instance }})"
          },
          "expr": "(elasticsearch_jvm_memory_used_bytes{area=\"heap\"} / elasticsearch_jvm_memory_max_bytes{area=\"heap\"}) * 100 > 90",
          "for": "5m",
          "labels": {
            "severity": "critical"
          }
        },
        {
          "alert": "ElasticsearchHeapUsageWarning",
          "annotations": {
            "description": "The heap usage is over 80% for 5m   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch Heap Usage warning (instance {{ $labels.instance }})"
          },
          "expr": "(elasticsearch_jvm_memory_used_bytes{area=\"heap\"} / elasticsearch_jvm_memory_max_bytes{area=\"heap\"}) * 100 > 80",
          "for": "5m",
          "labels": {
            "severity": "warning"
          }
        },
        {
          "alert": "ElasticsearchDiskSpaceLow",
          "annotations": {
            "description": "The disk usage is over 80%   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch disk space low (instance {{ $labels.instance }})"
          },
          "expr": "elasticsearch_filesystem_data_available_bytes / elasticsearch_filesystem_data_size_bytes * 100 < 20",
          "for": "5m",
          "labels": {
            "severity": "warning"
          }
        },
        {
          "alert": "ElasticsearchDiskOutOfSpace",
          "annotations": {
            "description": "The disk usage is over 90%   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch disk out of space (instance {{ $labels.instance }})"
          },
          "expr": "elasticsearch_filesystem_data_available_bytes / elasticsearch_filesystem_data_size_bytes * 100 < 10",
          "for": "5m",
          "labels": {
            "severity": "critical"
          }
        },
        {
          "alert": "ElasticsearchClusterRed",
          "annotations": {
            "description": "Elastic Cluster Red status   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch Cluster Red (instance {{ $labels.instance }})"
          },
          "expr": "elasticsearch_cluster_health_status{color=\"red\"} == 1",
          "for": "5m",
          "labels": {
            "severity": "critical"
          }
        },
        {
          "alert": "ElasticsearchClusterYellow",
          "annotations": {
            "description": "Elastic Cluster Yellow status   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch Cluster Yellow (instance {{ $labels.instance }})"
          },
          "expr": "elasticsearch_cluster_health_status{color=\"yellow\"} == 1",
          "for": "5m",
          "labels": {
            "severity": "warning"
          }
        },
        {
          "alert": "ElasticsearchHealthyNodes",
          "annotations": {
            "description": "Number Healthy Nodes less then number_of_nodes   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch Healthy Nodes (instance {{ $labels.instance }})"
          },
          "expr": "elasticsearch_cluster_health_number_of_nodes < number_of_nodes",
          "for": "5m",
          "labels": {
            "severity": "critical"
          }
        },
        {
          "alert": "ElasticsearchHealthyDataNodes",
          "annotations": {
            "description": "Number Healthy Data Nodes less then number_of_data_nodes   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch Healthy Data Nodes (instance {{ $labels.instance }})"
          },
          "expr": "elasticsearch_cluster_health_number_of_data_nodes < number_of_data_nodes",
          "for": "5m",
          "labels": {
            "severity": "critical"
          }
        },
        {
          "alert": "ElasticsearchRelocationShards",
          "annotations": {
            "description": "Number of relocation shards for 20 min   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch relocation shards (instance {{ $labels.instance }})"
          },
          "expr": "elasticsearch_cluster_health_relocating_shards > 0",
          "for": "5m",
          "labels": {
            "severity": "critical"
          }
        },
        {
          "alert": "ElasticsearchInitializingShards",
          "annotations": {
            "description": "Number of initializing shards for 10 min   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch initializing shards (instance {{ $labels.instance }})"
          },
          "expr": "elasticsearch_cluster_health_initializing_shards > 0",
          "for": "5m",
          "labels": {
            "severity": "warning"
          }
        },
        {
          "alert": "ElasticsearchUnassignedShards",
          "annotations": {
            "description": "Number of unassigned shards for 2 min   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch unassigned shards (instance {{ $labels.instance }})"
          },
          "expr": "elasticsearch_cluster_health_unassigned_shards > 0",
          "for": "5m",
          "labels": {
            "severity": "critical"
          }
        },
        {
          "alert": "ElasticsearchPendingTasks",
          "annotations": {
            "description": "Number of pending tasks for 10 min. Cluster works slowly.   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch pending tasks (instance {{ $labels.instance }})"
          },
          "expr": "elasticsearch_cluster_health_number_of_pending_tasks > 0",
          "for": "5m",
          "labels": {
            "severity": "warning"
          }
        },
        {
          "alert": "ElasticsearchNoNewDocuments",
          "annotations": {
            "description": "No new documents for 10 min!   VALUE = {{ $value }}   LABELS: {{ $labels }}",
            "summary": "Elasticsearch no new documents (instance {{ $labels.instance }})"
          },
          "expr": "rate(elasticsearch_indices_docs{es_data_node=\"true\"}[10m]) < 1",
          "for": "10m",
          "labels": {
            "severity": "warning"
          },
        },
        {
          "alert": "ElasticSearchDiskRunningFullIn24Hours",
          "annotations": {
            "description": "ElasticSearch node {{$labels.name}}: Data volume usage is above is running full within the next 24 hours (mounted at {{$labels.mount}})",
            "summary": "ElasticSearch node {{$labels.name}} running full within the next 24 hours",
          },
          "expr": "predict_linear(elasticsearch_filesystem_data_free_bytes[6h], 3600 * 24) < 0",
          "for": "30m",
          "labels": {
            "severity": "warning"
          },
        },
        {
          "alert": "ElasticSearchDiskRunningFullIn2Hours",
          "annotations": {
            "description": "ElasticSearch node {{$labels.name}}: Data volume usage is above is running full within the next 2 hours (mounted at {{$labels.mount}})",
            "summary": "ElasticSearch node {{$labels.name}} running full within the next 2 hours"
          },
          "expr": "predict_linear(elasticsearch_filesystem_data_free_bytes[30m], 3600 * 2) < 0",
          "for": "10m",
          "labels": {
            "severity": "critical"
          },
        },
        {
          "alert": "ElasticSearchDiskRunningFull80Percent",
          "annotations": {
            "description": "ElasticSearch node {{$labels.name}}: Data volume usage is {{ $value }}% (mounted at {{$labels.mount}})",
            "summary": "ElasticSearch node {{$labels.name}}: Data volume usage >80% detected"
          },
          "expr": "100 - (elasticsearch_filesystem_data_available_bytes / elasticsearch_filesystem_data_size_bytes) * 100 > 80",
          "for": "2m",
          "labels": {
            "severity": "warning"
          },
        },
        {
          "alert": "ElasticSearchDiskRunningFull90Percent",
          "annotations": {
            "description": "ElasticSearch node {{$labels.name}}: Data volume usage is {{ $value }}% (mounted at {{$labels.mount}})",
            "summary": "ElasticSearch node {{$labels.name}}: Data volume usage >90% detected"
          },
          "expr": "100 - (elasticsearch_filesystem_data_available_bytes / elasticsearch_filesystem_data_size_bytes) * 100 > 90",
          "for": "2m",
          "labels": {
            "severity": "critical"
          },
        },
      ],
    },
    ],
  },
}
