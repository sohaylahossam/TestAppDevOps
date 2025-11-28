# modules/monitoring/main.tf
# Prometheus and Grafana monitoring module for EKS

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
      monitoring = "enabled"
    }
  }
}

# Deploy kube-prometheus-stack using Helm
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.prometheus_chart_version

  # Wait for deployment to complete
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  # Prometheus configuration
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = var.prometheus_cpu_request
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = var.prometheus_memory_request
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.cpu"
    value = var.prometheus_cpu_limit
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = var.prometheus_memory_limit
  }

  # Service type for Prometheus
  set {
    name  = "prometheus.service.type"
    value = var.prometheus_service_type
  }

  set {
    name  = "prometheus.service.port"
    value = "9090"
  }

  # Enable service monitor selector
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  # Grafana configuration
  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "grafana.adminUser"
    value = var.grafana_admin_user
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.service.type"
    value = var.grafana_service_type
  }

  set {
    name  = "grafana.service.port"
    value = "80"
  }

  set {
    name  = "grafana.persistence.enabled"
    value = var.grafana_persistence_enabled
  }

  set {
    name  = "grafana.persistence.size"
    value = var.grafana_storage_size
  }

  # Alertmanager configuration
  set {
    name  = "alertmanager.enabled"
    value = var.alertmanager_enabled
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.alertmanager_storage_size
  }

  # Node exporter
  set {
    name  = "nodeExporter.enabled"
    value = "true"
  }

  # Kube state metrics
  set {
    name  = "kubeStateMetrics.enabled"
    value = "true"
  }

  # Default monitoring rules
  set {
    name  = "defaultRules.create"
    value = "true"
  }

  # Additional values from file
  values = var.additional_values != null ? [var.additional_values] : []

  depends_on = [kubernetes_namespace.monitoring]
}

# ServiceMonitor for custom application
resource "kubernetes_manifest" "app_service_monitor" {
  count = var.enable_app_monitoring ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${var.app_name}-monitor"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "prometheus"
        app     = var.app_name
      }
    }
    spec = {
      selector = {
        matchLabels = var.app_selector_labels
      }
      namespaceSelector = {
        matchNames = var.app_namespaces
      }
      endpoints = [
        {
          port     = var.app_metrics_port
          interval = var.scrape_interval
          path     = var.app_metrics_path
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus_stack]
}

# PrometheusRule for custom alerts
resource "kubernetes_manifest" "app_alerts" {
  count = var.enable_app_monitoring ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "${var.app_name}-alerts"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      labels = {
        release = "prometheus"
        app     = var.app_name
      }
    }
    spec = {
      groups = [
        {
          name     = var.app_name
          interval = "30s"
          rules = [
            {
              alert = "${var.app_name}Down"
              expr  = "up{job=\"${var.app_name}\"} == 0"
              for   = "5m"
              labels = {
                severity = "critical"
              }
              annotations = {
                summary     = "${var.app_name} is down"
                description = "${var.app_name} has been down for more than 5 minutes"
              }
            },
            {
              alert = "HighErrorRate"
              expr  = "rate(http_requests_total{job=\"${var.app_name}\",status=~\"5..\"}[5m]) > 0.05"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High error rate detected"
                description = "Error rate is above 5% for 5 minutes"
              }
            },
            {
              alert = "HighResponseTime"
              expr  = "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job=\"${var.app_name}\"}[5m])) > 1"
              for   = "10m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary     = "High response time"
                description = "95th percentile response time is above 1 second"
              }
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.prometheus_stack]
}

# Grafana dashboard ConfigMap
resource "kubernetes_config_map" "grafana_dashboards" {
  count = var.enable_custom_dashboards ? 1 : 0

  metadata {
    name      = "${var.app_name}-dashboards"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "${var.app_name}-dashboard.json" = var.custom_dashboard_json
  }

  depends_on = [helm_release.prometheus_stack]
}

# Data sources for outputs
data "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-kube-prometheus-prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  depends_on = [helm_release.prometheus_stack]
}

data "kubernetes_service" "grafana" {
  metadata {
    name      = "prometheus-grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  depends_on = [helm_release.prometheus_stack]
}

data "kubernetes_service" "alertmanager" {
  metadata {
    name      = "prometheus-kube-prometheus-alertmanager"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  depends_on = [helm_release.prometheus_stack]
}
