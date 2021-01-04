variable "image_tag" {
  type        = string
  description = "The Docker image tag to be specified in a task definition"
}

variable "environment" {
  type        = string
  description = "test, integration, staging or production"
}

variable "assume_role_arn" {
  type        = string
  description = "(optional) AWS IAM role to assume. Uses the role from the environment by default."
  default     = null
}
