# Introduction

## Setup

1. Clone https://github.com/p-se/fleet-dev-tools
2. Run `cd fleet-dev-tools/bin && 20.sh 10` to spin up 10 clusters
3.

```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install \
    --version 25.0.0 \
    --values prometheus-values.yaml \
    prometheus prometheus-community/prometheus
```

```shell
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install \
    -f setup/grafana-values.yaml \
    grafana grafana/grafana

kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

```shell
kubectl port-forward --namespace default svc/grafana 3000:80
kubectl port-forward --namespace default svc/prometheus-server 9090:80
```
