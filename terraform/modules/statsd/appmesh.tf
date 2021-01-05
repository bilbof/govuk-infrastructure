resource "aws_appmesh_virtual_service" "statsd" {
  name      = local.virtual_service_name
  mesh_name = var.mesh_name

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.statsd.name
      }
    }
  }
}

resource "aws_appmesh_virtual_node" "statsd" {
  name      = local.service_name
  mesh_name = var.mesh_name

  spec {
    backend {
      virtual_service {
        virtual_service_name = local.virtual_service_name
      }
    }

    listener {
      port_mapping {
        port     = local.ingress_port
        protocol = local.ingress_protocol
      }
    }

    service_discovery {
      aws_cloud_map {
        namespace_name = var.service_discovery_namespace_name
        service_name   = aws_service_discovery_service.statsd.name
      }
    }

    logging {
      access_log {
        file {
          path = "/dev/stdout"
        }
      }
    }
  }

  depends_on = [aws_service_discovery_service.statsd]
}
