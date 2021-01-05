resource "aws_service_discovery_service" "statsd" {
  name = local.service_name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 30
      type = "A"
    }

    routing_policy = "WEIGHTED"
  }
}
