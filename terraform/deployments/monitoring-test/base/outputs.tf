output "grafana_fqdn" {
  value       = module.monitoring.grafana_fqdn
  description = "Public Fully Qualified Domain Name for Grafana"
}
