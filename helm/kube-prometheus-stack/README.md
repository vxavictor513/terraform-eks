# prometheus-operator

## Notes

Grafana is included inside Prometheus helm chart, hence it will get installed along with Prometheus.
Grafana is installed with prebuilt Kubernetes & JVM dashboards.
Visit https://grafana.com/grafana/dashboards to import more dashboards.
Visit https://github.com/prometheus-community/helm-charts/tree/main/charts to add exporter plugins for more metrices scraping

## Getting Started

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade -i prometheus prometheus-community/kube-prometheus-stack -f ./helm/prometheus-operator/values.yaml
```
