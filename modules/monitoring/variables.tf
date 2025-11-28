# modules/monitoring/variables.tf

variable "namespace" {
  description = "Kubernetes namespace for monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "prometheus_chart_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "54.0.0"
}

# Prometheus Configuration
variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "30d"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "50Gi"
}

variable "prometheus_cpu_request" {
  description = "CPU request for Prometheus"
  type        = string
  default     = "500m"
}

variable "prometheus_memory_request" {
  description = "Memory request for Prometheus"
  type        = string
  default     = "2Gi"
}

variable "prometheus_cpu_limit" {
  description = "CPU limit for Prometheus"
  type        = string
  default     = "2000m"
}

variable "prometheus_memory_limit" {
  description = "Memory limit for Prometheus"
  type        = string
  default     = "4Gi"
}

variable "prometheus_service_type" {
  description = "Kubernetes service type for Prometheus (ClusterIP, LoadBalancer, NodePort)"
  type        = string
  default     = "LoadBalancer"
}

# Grafana Configuration
variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "grafana_service_type" {
  description = "Kubernetes service type for Grafana (ClusterIP, LoadBalancer, NodePort)"
  type        = string
  default     = "LoadBalancer"
}

variable "grafana_persistence_enabled" {
  description = "Enable persistence for Grafana"
  type        = bool
  default     = true
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "10Gi"
}

# Alertmanager Configuration
variable "alertmanager_enabled" {
  description = "Enable Alertmanager"
  type        = bool
  default     = true
}

variable "alertmanager_storage_size" {
  description = "Storage size for Alertmanager"
  type        = string
  default     = "10Gi"
}

# Application Monitoring
variable "enable_app_monitoring" {
  description = "Enable ServiceMonitor and alerts for custom application"
  type        = bool
  default     = false
}

variable "app_name" {
  description = "Name of the application to monitor"
  type        = string
  default     = "my-app"
}

variable "app_selector_labels" {
  description = "Labels to select application services"
  type        = map(string)
  default = {
    app = "my-app"
  }
}

variable "app_namespaces" {
  description = "Namespaces where application is deployed"
  type        = list(string)
  default     = ["default"]
}

variable "app_metrics_port" {
  description = "Port name for application metrics"
  type        = string
  default     = "metrics"
}

variable "app_metrics_path" {
  description = "Path for application metrics endpoint"
  type        = string
  default     = "/metrics"
}

variable "scrape_interval" {
  description = "Prometheus scrape interval"
  type        = string
  default     = "30s"
}

# Custom Dashboards
variable "enable_custom_dashboards" {
  description = "Enable custom Grafana dashboards"
  type        = bool
  default     = false
}

variable "custom_dashboard_json" {
  description = "JSON content for custom Grafana dashboard"
  type        = string
  default     = ""
}

# Additional Helm values
variable "additional_values" {
  description = "Additional values for Helm chart in YAML format"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
