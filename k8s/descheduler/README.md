# descheduler
Magic from https://github.com/kubernetes-sigs/descheduler/tree/v0.10.0

This will automatically balance pods across nodes, being careful with antiaffinity and disruptionbudget policies.

You can set thresholds in `configmap.yaml`. Nodes above `thresholds` but below `targetThresholds` are correctly provisioned, nodes with lower or higher resource usage will have their pods re-allocated. 
