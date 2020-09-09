# Kubernetes Alert Runbooks
This is an adaption from [kubernetes-mixin](https://github.com/kubernetes-monitoring/kubernetes-mixin).

As Rob Ewaschuk [puts it](https://docs.google.com/document/d/199PqyG3UsyXlwieHaqbGiWVa8eMWi8zzAn0YfcApr8Q/edit#):
> Playbooks (or runbooks) are an important part of an alerting system; it's best to have an entry for each alert or family of alerts that catch a symptom, which can further explain what the alert means and how it might be addressed.

It is a recommended practice that you add an annotation of "runbook" to every prometheus alert with a link to a clear description of it's meaning and suggested remediation or mitigation. While some problems will require private and custom solutions, most common problems have common solutions. In practice, you'll want to automate many of the procedures (rather than leaving them in a wiki), but even a self-correcting problem should provide an explanation as to what happened and why to observers.


# AlertmanagerFailedReload
This indicates an issue in AlertManager configuration and can be resolved in the alertmanager config maps. In order to troubleshoot, it is useful to look at the alertmanager logs for the config-reloader container.

# Watchdog
This alert is suppressed normally and should always be firing - if it isn't, it indicates an issue in Prometheus Alertmanager that may be preventing other alerts from getting through.

# KubeContainerWaiting
This indicates that a container is waiting to be scheduled. For some applications (eg. jaeger) it can indicate a configuration issue that should be investigated and addressed after checking the status and error on the appropriate pods. In other cases, it can indicate a cluster resourcing issue preventing pods from being scheduled - this is resolved by adding more resources (eg. new nodes).

# KubeletTooManyPods
This generally indicates a resource issue - too many pods on too few nodes in a particular area zone. Resolve it by scaling up the cluster.

# KubeDaemonSetMisScheduled
This indicates that a daemonset is scheduled on a node that it should not be scheduled on. In some cases, this is observed when AWS applies the node label `NodeWithImpairedVolumes=true:NoSchedule` after failing to attach an EBS volume - often, this is a transient issue within an EKS cluster. In order to resolve it, you can simply remove that taint from the node with `k edit no ${node_name}`.

# CPUThrottlingHigh
CPU usage is high for this one.

# KubeContainerWaiting
This often indicates an underlying issue in deployment configuration - look at the specs for the services and identify why they aren't successfully able to run.

# NoMessageForTooLong
This indicates that Kafka is not processing many messages. In inactive environments, this is often expected. It is suggested that you do a quick health check to make sure that Kafka is running okay and that messages are getting through from the apps.

# TargetDown
This indicates that Prometheus is having trouble spidering the metrics endpoint for a service. In some cases, this means that the service is down but it could alsoo indicate that Prometheus itself is overloaded. Refer to the Status -> Targets page on Prometheus for further detail.

# BridgeContainersDown
This means that Kafka Bridge containers are all unavailable - okay if you don't use Kafka Bridge, a problem if you do.

# ConnectContainersDown
This means that Kafka Connect containers are all unavailable - okay if you don't use Kafka Connect, a problem if you do.

# MirrorMakerContainersDown
This means that Kafka MirrorMaker containers are all unavailable - okay if you don't use Kafka MirrorMaker, a problem if you do.

## Other Kubernetes Runbooks and troubleshooting
+ [Troubleshoot Clusters ](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/)
+ [Cloud.gov Kubernetes Runbook ](https://cloud.gov/docs/ops/runbook/troubleshooting-kubernetes/)
+ [Recover a Broken Cluster](https://codefresh.io/Kubernetes-Tutorial/recover-broken-kubernetes-cluster/)
