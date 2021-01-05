variable "cluster_id" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "govuk_management_access_sg_id" {
  type        = string
  description = "Gives access to Graphite in EC2"
}

variable "internal_domain_name" {
  description = "Domain in which to create DNS records for private resources. For example, test.govuk-internal.digital"
  type        = string
}

variable "mesh_name" {
  type = string
}

variable "private_subnets" {
  description = "The subnet ids for govuk_private_a, govuk_private_b, and govuk_private_c"
  type        = list
}

variable "service_discovery_namespace_id" {
  type = string
}

variable "service_discovery_namespace_name" {
  type = string
}

variable "statsd_security_group_id" {
  type        = string
  description = "Security group for Statsd ECS Service"
}

variable "task_role_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}
