# modules/monitoring/outputs.tf

output "namespace" {
  description = "Monitoring namespace name"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_endpoint" {
  description = "Prometheus service endpoint"
  value = var.prometheus_service_type == "LoadBalancer" ? (
    length(data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress) > 0 ?
    try(data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].hostname, 
        data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].ip,
        "pending") : "pending"
  ) : "${data.kubernetes_service.prometheus.metadata[0].name}.${data.kubernetes_service.prometheus.metadata[0].namespace}.svc.cluster.local:9090"
}

output "grafana_endpoint" {
  description = "Grafana service endpoint"
  value = var.grafana_service_type == "LoadBalancer" ? (
    length(data.kubernetes_service.grafana.status[0].load_balancer[0].ingress) > 0 ?
    try(data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].hostname,
        data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].ip,
        "pending") : "pending"
  ) : "${data.kubernetes_service.grafana.metadata[0].name}.${data.kubernetes_service.grafana.metadata[0].namespace}.svc.cluster.local"
}

output "alertmanager_endpoint" {
  description = "Alertmanager service endpoint"
  value       = "${data.kubernetes_service.alertmanager.metadata[0].name}.${data.kubernetes_service.alertmanager.metadata[0].namespace}.svc.cluster.local:9093"
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = var.grafana_admin_user
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "prometheus_url" {
  description = "Full Prometheus URL"
  value = var.prometheus_service_type == "LoadBalancer" ? (
    length(data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress) > 0 ?
    "http://${try(data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].hostname,
                  data.kubernetes_service.prometheus.status[0].load_balancer[0].ingress[0].ip,
                  "pending")}:9090" : "pending"
  ) : "http://${data.kubernetes_service.prometheus.metadata[0].name}.${data.kubernetes_service.prometheus.metadata[0].namespace}.svc.cluster.local:9090"
}

output "grafana_url" {
  description = "Full Grafana URL"
  value = var.grafana_service_type == "LoadBalancer" ? (
    length(data.kubernetes_service.grafana.status[0].load_balancer[0].ingress) > 0 ?
    "http://${try(data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].hostname,
                  data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].ip,
                  "pending")}" : "pending"
  ) : "http://${data.kubernetes_service.grafana.metadata[0].name}.${data.kubernetes_service.grafana.metadata[0].namespace}.svc.cluster.local"
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.prometheus_stack.name
}

output "helm_release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.prometheus_stack.namespace
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.prometheus_stack.status
}
