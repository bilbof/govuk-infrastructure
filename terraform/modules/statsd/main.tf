terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

locals {
  ingress_port         = 8125
  ingress_protocol     = "tcp"
  service_name         = "statsd"
  virtual_service_name = "${local.service_name}.${var.service_discovery_namespace_name}"
}

module "task_definition" {
  source                  = "../task-definition"
  mesh_name               = var.mesh_name
  service_name            = local.service_name
  cpu                     = 512
  memory                  = 1024
  execution_role_arn      = var.execution_role_arn
  task_role_arn           = var.task_role_arn
  container_ingress_ports = local.ingress_port

  container_definitions = [
    {
      "name" : local.service_name,
      "image" : "govuk/statsd:test-0.1.2",
      "essential" : true,
      "dependsOn" : [{
        "containerName" : "envoy",
        "condition" : "START"
      }],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-create-group" : "true",
          "awslogs-group" : "awslogs-fargate",
          "awslogs-region" : "eu-west-1",                           # TODO: hard coded
          "awslogs-stream-prefix" : "awslogs-${local.service_name}" # TODO: should this be cluster-aware?
        }
      },
      "mountPoints" : [],
      "portMappings" : [
        {
          "containerPort" : local.ingress_port,
          "protocol" : local.ingress_protocol
        }
      ]
    }
  ]
}

resource "aws_ecs_service" "service" {
  name            = local.service_name
  cluster         = var.cluster_id
  desired_count   = 1
  launch_type     = "FARGATE"
  task_definition = module.task_definition.arn

  network_configuration {
    security_groups = [var.service_security_group_id, var.govuk_management_access_sg_id]
    subnets         = var.private_subnets
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.statsd.arn
    container_name = local.service_name
  }
}
