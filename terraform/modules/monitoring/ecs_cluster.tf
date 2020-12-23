# All monitoring services running in its own monitoring cluster.
resource "aws_ecs_cluster" "cluster" {
  name               = "monitoring"
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = var.ecs_default_capacity_provider
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
