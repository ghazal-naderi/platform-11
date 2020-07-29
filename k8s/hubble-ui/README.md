# hubble-ui
This is a copy of `hubble-ui` from [cilium/cilium@v1.8.2/install/kubernetes/cilium/charts](https://github.com/cilium/cilium/tree/v1.8.2/install/kubernetes/cilium/charts) with the `validation.yaml` removed in order to allow independent installation. It is required when wanting to install `hubble-ui` on a `kops` managed installation `kops>=1.9` when Hubble and Cilium are enabled.

## Installation
- Edit `cluster` with `kops edit cluster` and ensure settings for `cilium` are as follows:
```
networking:
  cilium:
    preallocateBPFMaps: true
    version: v1.8.2
    hubble:
      enabled: true
      metrics:
      - dns
      - drop
      - flow
      - http
      - icmp
      - port-distribution 
      - tcp
```
- Edit the `cilium-config` `ConfigMap` in `kube-system` in order to add the parameter `hubble-listen-address` with the value `:4244` (FIXME: this should really be added upstream)
- Initiate the `kops update` and rolling-node updates in order to apply changes.
- Create ingress for Cilium Hubble (eg. hubble.sandbox.11fs-structs.com) protected with the `auth` struct annotations 
