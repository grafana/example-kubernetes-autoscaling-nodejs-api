# Node API Auto Scaling Example

This is an example project that demonstrates how to auto scale an application running in Kubernetes using Keda.

## Prerequisites

You'll need to have the following installed:

- [k6](https://k6.io/docs/getting-started/installation)
- Node.js
- Docker
- GNU Make
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)

Here's a handy tutorial for [Ubuntu 18:04](https://computingforgeeks.com/how-to-install-minikube-on-ubuntu-18-04/) users. The instructions written for this project are meant for `minikube`. However, they can be modified to adapt to a different Kubernetes implementation.

## ENVIRONMENT SETUP

### 1. Configure Minikube

Once your minikube is up and running, enable the following addons:

```bash
$ minikube addons enable dashboard
$ minikube addons enable ingress # optional
$ minikube addons enable ingress-dns # optional
```

To access dashboard, type the following command from a terminal: `minikube dashboard`. You'll need to open a separate terminal and execute the following:

```bash
minikube tunnel
```

This will allow you to easily access `ClusterPort` services via your web browser.

### 2. Deploy Prometheus, and Kube State Metrics Server

We need to be able to collect and track metrics about our application. We'll use the following:

- [Kube State metrics](https://github.com/kubernetes/kube-state-metrics): This is a service that extracts various metrics about all Kubernetes API objects such as deployments, pods e.t.c. Follow these [instructions](https://devopscube.com/setup-kube-state-metrics/) to deploy Kube State Metrics server to minikube.

- [Prometheus](https://prometheus.io/) is an open source monitoring framework that scrapes(collects) metrics data from various sources such as the Kube State Metrics server. We can use it's query language to extract the information we need to determine if our application needs to be extracted. Use these [instructions](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/) to deploy Prometheus to minikube.

### 3. Install InfluxDb and Grafana Locally

We can deploy InfluxDb and Grafana to Kubernetes as well. However, it's faster installing them locally:

- InfluxDB
- Grafana

Ensure the above services are running. If you are on Linux, you can start with the command:

```bash
sudo systemctl start influxdb grafana-server
```

Once Grafana is installed, you'll need to add **Prometheus** and **InfluxDB** as a data source.

### 4. Deploy Keda

- [Keda]() will scale up or down our application based on the threshold we provide it. Follow these [instructions](https://keda.sh/docs/deploy/#yaml) to deploy Keda to minikube.

At this point, Keda isn't configured to do anything.

### 5. Deploy Application

Execute the following commands to download and run the project in your workspace:

```bash
git clone git@github.com:k6io/node-api-autoscaling-example.git
cd test-node-api-k6
npm i
npm run dev
```

Point your browser URL to `localhost:4000`. Any changes you make to your source code will restart the server. You can also test the API from your command line like this:

```bash
curl http://localhost:4000/crocodile
```

Next, deploy the application to Minikube, your Kubernetes node. Lucky for you, I've simplified the process. Just execute this one command:

```bash
make image # build and upload docker image to minikube environment
make apply # deploy crocodile-api and expose service
```

If you don't have GNU make on you platform, simply execute the following commands in a new terminal:

```bash
# build and upload docker image to minikube environment
eval $(minikube docker-env)
docker image prune -f
docker build -t brandiqa/crocodile-api .

# deploy crocodile-api and expose service
kubectl apply -f deploy/crocodile-deployment.yml
```

Execute the command to command `kubectl get pods` to confirm the pod is running.

[todo screenshot]

Execute the command to command `kubectl get services` to confirm the service is running. To ensure the service is exposed, perform a curl operation:

```bash
curl 10.98.55.109:4000/crocodiles # replace ip address
```

If you get a timeout, ensure `minikube tunnel` is running on a separate terminal.

### 6. Run Load Testing without AutoScaling

In this step, will run load testing test and send metrics to `influxdb`. Navigate to the root of the project and execute:

```bash
# replace ip address
HOSTNAME=10.98.55.109:4000/crocodiles k6 run -o influxdb=http://localhost:8086/k6 performance-test.js
```

### 7. Run Load Testing WITH AutoScaling

First deploy Keda's `scaledobject` configuration that scales up the project if the Prometheus expression, `sum(rate(node_http_requests_total[2m]))` exceeds 50 HTTP requests per second.

```bash
kubectl deploy -f keda/keda-prometheus-scaledobject.yml
```

Next, run the `performance-test.js` again. You should see the number of pods gradually increase as traffic increases.
