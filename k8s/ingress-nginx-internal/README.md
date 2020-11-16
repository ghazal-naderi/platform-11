# ingress-nginx-internal
This provides the capability to create a new ingress controller to manage ingresses with the class "nginx-internal" on a L4 load balancers via nginx on an internal subnet.

In order to customize the ELB to enable it to be hosted on an internal subnet kustomize the following annotation.

```
kind: Service
apiVersion: v1
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
  ports:
    - name: http
      port: 80
      protocol: TCP
      targetPort: http
    - name: https
      port: 443
      protocol: TCP
      targetPort: https
```

It is also required to add the parameter `use-proxy-protocol: "true"` to the `ingress-nginx` `ConfigMap`.

```
apiVersion: v1
data:
  use-proxy-protocol: "true"
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
  name: nginx-configuration
  namespace: ingress-nginx
```

For Oracle Kustomize the following annotations.

```
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: ingress-nginx-internal
    app.kubernetes.io/part-of: ingress-nginx-internal
  name: ingress-nginx-internal
  annotations:
    service.beta.kubernetes.io/oci-load-balancer-shape: "100Mbps|400Mbps|800Mbps"
    service.beta.kubernetes.io/oci-load-balancer-internal: "true"
    service.beta.kubernetes.io/oci-load-balancer-subnet1: "ocid1..."
  namespace: ingress-nginx-internal
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: http
  - name: https
    port: 443
    protocol: TCP
    targetPort: https
  selector:
    app.kubernetes.io/name: ingress-nginx-internal
    app.kubernetes.io/part-of: ingress-nginx-internal
  type: LoadBalancer
```
