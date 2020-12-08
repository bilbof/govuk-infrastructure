terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

module "app" {
  source                           = "../../app"
  execution_role_arn               = var.execution_role_arn
  vpc_id                           = var.vpc_id
  cluster_id                       = var.cluster_id
  service_name                     = var.service_name
  subnets                          = var.private_subnets
  mesh_name                        = var.mesh_name
  service_discovery_namespace_id   = var.service_discovery_namespace_id
  service_discovery_namespace_name = var.service_discovery_namespace_name
  extra_security_groups            = [var.govuk_management_access_security_group]
  desired_count                    = var.desired_count

  load_balancers = [{
    target_group_arn = aws_lb_target_group.public.arn
    container_name   = var.service_name
    container_port   = 80
  }]
}

#
# Internet-facing load balancer
#

# TODO: use a single, ACM-managed cert with both domains on. There is already
# such a cert in integration/staging/prod (but it needs defining in Terraform).
data "aws_acm_certificate" "public_lb_default" {
  domain   = "*.test.govuk.digital"
  statuses = ["ISSUED"]
}

data "aws_acm_certificate" "public_lb_alternate" {
  domain   = "*.test.publishing.service.gov.uk"
  statuses = ["ISSUED"]
}

resource "aws_lb" "public" {
  name               = "${var.service_name}-${terraform.workspace}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_alb.id]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "public" {
  name        = "${var.service_name}-${terraform.workspace}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }

  depends_on = [aws_lb.public]
}

resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.public_lb_default.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public.arn
  }
}

resource "aws_lb_listener_certificate" "publishing_service" {
  listener_arn    = aws_lb_listener.public.arn
  certificate_arn = data.aws_acm_certificate.public_lb_alternate.arn
}

resource "aws_security_group" "public_alb" {
  name        = "fargate_${var.service_name}_${terraform.workspace}_public_alb"
  vpc_id      = var.vpc_id
  description = "${var.service_name} Internet-facing ALB"
}

resource "aws_route53_record" "public_alb" {
  zone_id = var.public_hosted_zone_id
  name    = var.service_name
  type    = "A"

  alias {
    name                   = aws_lb.public.dns_name
    zone_id                = aws_lb.public.zone_id
    evaluate_target_health = true
  }
}
