variable "name" {
  type = string
}
variable "image" {
  type = string
}
variable "environment_variables" {
  type = map
}
variable "log_group" {
  type = string
}
variable "secrets_from_arns" {
  type = map
}
variable "aws_region" {
  type = string
}
variable "depends_on_containers" {
  type        = map
  default     = {}
  description = "Other containers which this depends on (e.g. for envoy, set this to {envoy: \"START\"})"
}

output "value" {
  value = {
    "name" : var.name,
    "image" : var.image,
    "essential" : true,
    "environment" : [for key, value in var.environment_variables : { name : key, value : tostring(value) }],
    "dependsOn" : [for key, value in var.depends_on_containers : { containerName : key, condition : value }],
    "logConfiguration" : {
      "logDriver" : "awslogs",
      "options" : {
        "awslogs-create-group" : "true", # TODO create the log group in terraform so we can configure the retention policy
        "awslogs-group" : var.log_group,
        "awslogs-region" : var.aws_region,
        "awslogs-stream-prefix" : var.name,
      }
    },
    "mountPoints" : [],
    "portMappings" : [
      {
        "containerPort" : 80,
        "hostPort" : 80,
        "protocol" : "tcp"
      }
    ],
    "secrets" : [for key, value in var.secrets_from_arns : { name : key, valueFrom : value }]
  }
}

