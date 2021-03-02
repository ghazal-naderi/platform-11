# cert-manager
Version `v1.2.0`

## Requirements
`ingress-nginx`

## Internal Ingress
For secure environments, be sure to add `ingress-nginx-internal`. You can then add the parameters:
```
        - --dns01-recursive-nameservers-only
        - --dns01-recursive-nameservers=1.1.1.1:53
        - --dns01-recursive-nameservers=8.8.8.8:53
```

to the `cert-manager` `Deployment` in order to resolve DNS from an external source and, eg.

```
    - selector:
        matchLabels: 
          internal: "true"
      dns01:
        route53:
          region: us-east-1
          hostedZoneId: ABCCDDDDDDD
```
to the `letsencrypt-prod` `ClusterIssuer` `solvers` in order to automatically create DNS entries into the provided (public) hosted zone in order to automatically validate certificates without requiring to serve the components for public consumption.

Note that all `Certificate`s that are internal-only should be labelled `internal: "true"` in order to ensure that they validate via DNS.

## Upgrade process (old)
Unfortunately this is a manual operation. In this process, I was upgrading from `v0.8.1` to `v0.14.1`. If you are already running `v0.11.0` or higher, steps 1-4 are likely unnecessary:

1. Get all old certs

```
kubectl get certificate --all-namespaces \
    -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].kind,OLD FORMAT:.spec.acme"
```

2. Export old certs

```
kubectl get -o yaml \                                                                                                                                                     	--all-namespaces \
     issuer,clusterissuer,certificates > ~/cert-manager-old-backup.yam
```

3. Remove `spec`->`acme` from `Certificates` and `spec`->`http01/dns01` from `(Cluster)Issuers`

```
cp ~/cert-manager-old-backup.yaml ~/cert-manager-new.yaml
vi ~/cert-manager-new.yaml
```

4. Change apiVersion on all resources from `certmanager.k8s.io/v1alpha1` to `cert-manager.io/v1alpha2`

```
gsed -i ~/cert-manager-new.yaml -e 's%certmanager.k8s.io/v1alpha1%cert-manager.io/v1alpha2%g'
```

5. Delete old `cert-manager`

```
kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v0.8.1/cert-manager.yaml
```

7. Make sure old `CRD`s are gone

```
kubectl get crd | grep certmanager.k8s.io
```

8. Install new `cert-manager`

```
kubectl apply \
       --validate=false \
       -f https://github.com/jetstack/cert-manager/releases/download/v0.14.1/cert-manager-legacy.yaml
```

9. Re-install all certificates with changed `apiVersion` and adjusted `spec`

```
kubectl apply -f ~/cert-manager-old-backup.yaml
```

9. Verify new version is running

```
kubectl get pods --namespace cert-manager
```

10. Edit a certificate and change `dnsNames` to force a refresh then check `Order` passes successfully

```
k edit certificate -n ...
k get orders -n ...
```

Please disable validation for applying, eg.
```
kubectl apply \
       --validate=false \
       -f https://github.com/jetstack/cert-manager/releases/download/v0.14.1/cert-manager-legacy.yaml
```
