# ECK struct
## Setup
In order to get logs, you must also obtain the `fluentd` struct - please read it's `README.md` for necessary pre-requisites. You must install the `eck` struct before the `fluentd` struct.

Once ECK is deployed, you can access Kibana at `kibana.example.com` with `example.com` being your domain. 

A standard setup on Kibana is to:
- Create default index pattern `logstash-*` using `@timestamp`
- Create a role for developer use with name `developer`, cluster privileges `read_ccr, read_slm, read_ilm, monitor, monitor_data_frame_transforms, monitor_ml, monitor_rollup, monitor_snapshot, monitor_transform, monitor_watcher`, privileges on `logstash-*` indices as `monitor, read, read_cross_cluster, index, view_index_metadata, create_doc, create` and `Global` `Read` permission on Kibana.
- Create a user for developer use with roles `kibana_user, apm_user, enrich_user, machine_learning_user, monitoring_user, reporting_user, rollup_user, snapshot_user, transform_user, watcher_user, developer` 

## ILM
To enable ILM in order to rotate out indexes as they age, you should:

- Create lifecycle policy then index template named `logstash` with pattern `logstash-*` and lifecycle, settings, alias as follows:
```
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_age": "7d",
            "max_size": "2gb"
          },
          "set_priority": {
            "priority": 20
          }
        }
      },
      "warm": {
        "actions": {
          "set_priority": {
            "priority": 90
          }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "freeze": {},
          "set_priority": {
            "priority": 0
          }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```
```
{
  "number_of_shards": 1,
  "number_of_replicas": 1,
  "index.lifecycle.name": "logstash-lifecycle-policy",
  "index.lifecycle.rollover_alias": "logstash"
}
```
```
{
    "logstash": {
      "is_write_index": true
    }
}
```
