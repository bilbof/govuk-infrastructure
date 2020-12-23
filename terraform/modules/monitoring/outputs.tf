output "grafana_fqdn" {
  value       = "${aws_route53_record.grafana_public_alb.name}.${var.public_lb_domain_name}"
  description = "Public Fully Qualified Domain Name for Grafana"
}
