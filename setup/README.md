# Introduction

## Setup

1. Clone https://github.com/p-se/fleet-dev-tools
2. Run `cd fleet-dev-tools/bin && 20.sh 10` to spin up 10 clusters
3. Install Prometheus (including Kubernetes integration)

```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install -n monitoring --create-namespace \
    --version 25.0.0 \
    --values prometheus-values.yaml \
    prometheus prometheus-community/prometheus
kubectl -n monitoring get configmap prometheus-server -o yaml \
    | sed 's/job_name: kubernetes-apiservers/job_name: apiserver/' \
    | kubectl replace -f -
```
> NOTE: rename one of the scraping jobs to match expectations from the Grafana dashboard

4. Install Grafana (including pre-loaded Kubernetes dashboards)

```shell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install -n monitoring --create-namespace \
    --version 6.60.1 \
    --values grafana-values.yaml \
    grafana grafana/grafana

kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

5. Access Prometheus and Grafana
    1. Using port-forward

    ```shell
    kubectl port-forward --namespace default svc/grafana 3000:80
    kubectl port-forward --namespace default svc/prometheus-server 9090:80
    ```

    2. Using minikube

    ```shell
    minikube service --namespace monitoring prometheus-server grafana
    ```

### Tips

* Create annotations programmatically:
```shell
kubectl -n monitoring exec -ti deploy/grafana -- \
    curl -v -H 'Content-Type: application/json' -d'{"what": "Test annotation", "tags": ["test"]}' \
        -u "admin:$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)" \
        http://localhost:3000/api/annotations/graphite
```

## Sources

### Dashboards

Dashboards are taken from [dotdc/grafana-dashboards-kubernetes](https://github.com/dotdc/grafana-dashboards-kubernetes#install-manually) project.
