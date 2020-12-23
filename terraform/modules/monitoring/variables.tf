variable "ecs_default_capacity_provider" {
  description = "Set this to FARGATE_SPOT to use spot instances in the ECS cluster by default. If unset, the cluster will use on-demand (regular) instances by default. Tasks can still override the default capacity provider in either case."
  type        = string
  default     = "FARGATE"
}

variable "execution_role_arn" {
  description = "For use during bootstrapping ECS services"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  description = "Subnet IDs to use for non-Internet-facing resources."
  type        = list
}

variable "public_subnets" {
  description = "Subnet IDs to use for Internet-facing resources."
  type        = list
}

variable "mesh_name" {
  type = string
}

variable "service_discovery_namespace_id" {
  type = string
}

variable "service_discovery_namespace_name" {
  type = string
}

variable "public_lb_domain_name" {
  description = "Domain in which to create DNS records for the app's Internet-facing load balancer. For example, staging.govuk.digital"
  type        = string
}

variable "govuk_management_access_sg_id" {
  description = "ID of security group (from the govuk-aws repo) for access from jumpboxes etc. This SG is added to all ECS instances."
  type        = string
}

variable "desired_count" {
  description = "Desired count of Application instances"
  type        = number
  default     = 1
}

variable "office_cidrs_list" {
  description = "List of GDS office CIDRs"
  type        = list
  default     = ["213.86.153.212/32", "213.86.153.213/32", "213.86.153.214/32", "213.86.153.235/32", "213.86.153.236/32", "213.86.153.237/32", "85.133.67.244/32"]
}
