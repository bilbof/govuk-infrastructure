terraform {
  backend "s3" {
    bucket  = "govuk-terraform-test"
    key     = "projects/grafana.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-west-1"

  assume_role {
    role_arn = var.assume_role_arn
  }
}

provider "random" {}

data "aws_region" "current" {}

# TODO pass this ARN in from the govuk deployment (via terraform remote state) instead of using a data source
data "aws_iam_role" "execution" {
  name = "fargate_execution_role"
}

# TODO pass this ARN in from the govuk deployment (via terraform remote state) instead of using a data source
data "aws_iam_role" "task" {
  name = "grafana_task_role"
}

data "terraform_remote_state" "govuk" {
  backend   = "s3"
  workspace = terraform.workspace
  config = {
    bucket   = "govuk-terraform-test"
    key      = "projects/govuk.tfstate"
    region   = data.aws_region.current.name
    role_arn = var.assume_role_arn
  }
}

data "terraform_remote_state" "monitoring" {
  backend = "s3"
  config = {
    bucket   = "govuk-terraform-test"
    key      = "projects/monitoring.tfstate"
    region   = "eu-west-1"
    role_arn = var.assume_role_arn
  }
}

data "aws_secretsmanager_secret" "github_client_id" {
  name = "grafana_github_client_id"
}

data "aws_secretsmanager_secret" "github_client_secret" {
  name = "grafana_github_client_secret"
}


resource "random_string" "grafana_password" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "grafana_password" {
  name = "grafana_password"
}

resource "aws_secretsmanager_secret_version" "grafana_password" {
  secret_id     = aws_secretsmanager_secret.grafana_password.id
  secret_string = random_string.grafana_password.result
}

locals {
  log_group = data.terraform_remote_state.govuk.outputs.log_group
  mesh_name = data.terraform_remote_state.govuk.outputs.mesh_name

  environment_variables = {
    GF_SECURITY_ADMIN_USER               = "admin",
    GF_AUTH_GITHUB_ENABLED               = true,
    GF_AUTH_GITHUB_SCOPES                = "user:email,read:org",
    GF_AUTH_GITHUB_AUTH_URL              = "https://github.com/login/oauth/authorize",
    GF_AUTH_GITHUB_TOKEN_URL             = "https://github.com/login/oauth/access_token",
    GF_AUTH_GITHUB_API_URL               = "https://api.github.com/user",
    GF_AUTH_GITHUB_ALLOW_SIGN_UP         = true,
    GF_AUTH_GITHUB_ALLOWED_ORGANIZATIONS = "alphagov",
    GF_SERVER_DOMAIN                     = data.terraform_remote_state.monitoring.outputs.grafana_fqdn,
    GF_SERVER_ROOT_URL : "https://%(domain)s"
  }

  secrets_from_arns = {
    GF_AUTH_GITHUB_CLIENT_ID     = data.aws_secretsmanager_secret.github_client_id.arn,
    GF_AUTH_GITHUB_CLIENT_SECRET = data.aws_secretsmanager_secret.github_client_secret.arn,
    GF_SECURITY_ADMIN_PASSWORD   = aws_secretsmanager_secret_version.grafana_password.arn,
  }
}

module "container_definition" {
  source                = "../../../modules/app-container-definition"
  name                  = "grafana"
  image                 = "grafana/grafana:${var.image_tag}"
  log_group             = local.log_group
  aws_region            = data.aws_region.current.name
  ports                 = [3000]
  environment_variables = local.environment_variables
  secrets_from_arns     = local.secrets_from_arns
  depends_on_containers = { envoy : "START" }
}

module "envoy_configuration" {
  source = "../../../modules/envoy-configuration"

  mesh_name    = local.mesh_name
  service_name = "grafana"
  log_group    = local.log_group
  aws_region   = data.aws_region.current.name
  port         = "3000"
}

resource "aws_ecs_task_definition" "grafana" {
  family                   = "grafana"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    module.container_definition.value,
    module.envoy_configuration.container_definition,
  ])

  network_mode       = "awsvpc"
  cpu                = 512
  memory             = 1024
  task_role_arn      = data.aws_iam_role.task.arn
  execution_role_arn = data.aws_iam_role.execution.arn
}
