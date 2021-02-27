# terraform-eks

This is a Terraform project to spin up a simple AWS EKS cluster in a new VPC.

## Versions

- Terraform 0.14.7
- Kubernetes 1.19

## Steps

1. Create AWS resources

```shell
terraform plan
terraform apply
```

2. Configure `kubectl` by editing `~/.kube/config`.

3. Create secret `regcred` for accessing private container registry.

4. Apply External DNS. https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md#manifest-for-clusters-with-rbac-enabled.

5. Apply NGINX ingress controller. See https://kubernetes.github.io/ingress-nginx/deploy/#tls-termination-in-aws-load-balancer-elb.

6. Create ingress to verify, https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md#verify-externaldns-works-ingress-example.

7. Create Route53 record manually for ingress controller load balancer.

8. Install Prometheus + Grafana from https://github.com/prometheus-community/helm-charts/tree/main/charts

```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade -i prometheus prometheus-community/kube-prometheus-stack -f ./helm/kube-prometheus-stack/values.yaml
```

9. Enable Kubernetes Metrics Server, https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html

- Note: Versioning of Helm chart?

- Note: https://grafana.com/grafana/dashboards/11159

- Note:

```
CREATE TABLE logs (
  id SERIAL PRIMARY KEY,
  timestamp TIMESTAMP NOT NULL,
  message TEXT
);
```

```
helm upgrade -i server-components-demo helm --set image.tag=latest
```

```
helm upgrade -i elasticsearch elastic/elasticsearch -f helm/elasticsearch/values.yaml
```

```
helm upgrade -i kibana elastic/kibana -f helm/kibana/values.yaml
```

https://github.com/fluent/fluentd-kubernetes-daemonset
