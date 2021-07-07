
## AWS Load Balancer Controller

AWS Load Balancer Controller is a controller to help manage Elastic Load Balancers for a Kubernetes cluster.

See more info for version https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/install/v2_2_1_full.yaml


## Configuring the ALB

The Deployment and a service classic LoadBalancer (NodePort instead ) to point to the same port should be as follow: 

```
apiVersion: v1
kind: Namespace
metadata:
  labels:
    app: my-app  
  name: dev
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: my-app
  name: my-app-deployment
  namespace: dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: my-app
  template:
    metadata:
      labels:
        app.kubernetes.io/name: my-app
    spec:
      containers:
      - image: my-app
        imagePullPolicy: Always
        name: my-app-latest
        ports:
        - containerPort: 3000
          name: app-port
          protocol: TCP
      restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  namespace: dev
  name: my-app-service
spec:
  ports:
    - port: 3000
      targetPort: 3000
      protocol: TCP
  type: LoadBalancer
  selector:
    app.kubernetes.io/name: my-app

```

The actual ALB ingress will going to have the following cdefination : 

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:140554600707:certificate/9a9d5353-9ca3-4115-a07e-997829385d4d
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
  name: my-app-alb
  namespace: dev
spec:
  rules:
  - http:
      paths:
      - path: /*
        pathType: Prefix
        backend:
          service:
            name: ssl-redirect
            port:
              number: 443
      - path: /*
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 3000
---
kind: Service
apiVersion: v1
metadata:
  name: ssl-redirect
  namespace: dev
spec:
  type: NodePort
  selector:
    app.kubernetes.io/name: my-app
  ports:
  - port: 443
    targetPort: 8080
    protocol: TCP  
    nodePort: 30007  

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: my-app
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: my-app
    spec:
      containers:
        - name: hello-world
          image: gcr.io/google-samples/node-hello:1.0
          ports:
            - containerPort: 8080
              protocol: TCP
```
To enable default http backend we will need to have the Deployment and service as below:

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: default-http-backend
  labels:
    app: default-http-backend
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: default-http-backend
  template:
    metadata:
      labels:
        app: default-http-backend
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: default-http-backend
        # Any image is permissible as long as:
        # 1. It serves a 404 page at /
        # 2. It serves 200 on a /healthz endpoint
        image: gcr.io/google_containers/defaultbackend:1.4
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          timeoutSeconds: 5
        ports:
        - containerPort: 8080
        resources:
          limits:
            cpu: 10m
            memory: 20Mi
          requests:
            cpu: 10m
            memory: 20Mi
---

apiVersion: v1
kind: Service
metadata:
  name: default-http-backend
  namespace: dev
  labels:
    app: default-http-backend
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: default-http-backend
```
Notes: 

1. This Load Blancer Controller will take use of environement variable for passing the value of `KOPS_CLUSTER_NAME` as cluster-name in `spec.containers.args`.
2. Make sure the cluster has prper permission preior to deploy this controler. please see the document here for further info. https://github.com/11FSConsulting/platform/tree/master/terraform/aws-iam-polici-loadbalancer
3. Install the controller as dependencies on the cluster.
4. Configure the ALB as provided here.



