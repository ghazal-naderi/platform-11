# cilium-eni-helper
This is a simple CronJob that will periodically enforce the setting `spec.eni.first-interface-index: 0` on CiliumNodes for autoscaling/post-configuration purposes. This setting is required in order to take advantage of the full IP pool available to Cilium Nodes using ENI networking. It requires no `kustomization` beyond the struct and should work 'out the box'.
