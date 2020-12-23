module "grafana" {
  source                           = "../app"
  execution_role_arn               = var.execution_role_arn
  vpc_id                           = var.vpc_id
  cluster_id                       = aws_ecs_cluster.cluster.id
  service_name                     = "grafana"
  subnets                          = var.private_subnets
  mesh_name                        = var.mesh_name
  service_discovery_namespace_id   = var.service_discovery_namespace_id
  service_discovery_namespace_name = var.service_discovery_namespace_name
  extra_security_groups            = [var.govuk_management_access_sg_id]
  desired_count                    = var.desired_count
  custom_container_services        = [{ container_service = "grafana", port = 3000, protocol = "http" }]

  load_balancers = [{
    target_group_arn = aws_lb_target_group.grafana_public.arn
    container_name   = "grafana"
    container_port   = 3000
  }]
}

#
# IAM
#

resource "aws_iam_role" "grafana_task" {
  name        = "grafana_task_role"
  description = "Role for GOV.UK Publishing app containers (ECS tasks) to talk to other AWS services."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Proxy authorization for Grafana
# https://docs.aws.amazon.com/app-mesh/latest/userguide/proxy-authorization.html
resource "aws_iam_role_policy_attachment" "grafana_appmesh_envoy_access" {
  role       = aws_iam_role.grafana_task.id
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshEnvoyAccess"
}

resource "aws_iam_role_policy_attachment" "grafana_cloudwatch_read_access" {
  role       = aws_iam_role.grafana_task.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
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

resource "aws_lb" "grafana_public" {
  name               = "fargate-public-grafana"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.grafana_public_alb.id]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "grafana_public" {
  name        = "grafana-public"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/api/health"
  }

  depends_on = [aws_lb.grafana_public]
}

resource "aws_lb_listener" "grafana_public" {
  load_balancer_arn = aws_lb.grafana_public.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.public_lb_default.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_public.arn
  }
}

resource "aws_lb_listener_certificate" "publishing_service" {
  listener_arn    = aws_lb_listener.grafana_public.arn
  certificate_arn = data.aws_acm_certificate.public_lb_alternate.arn
}

resource "aws_security_group" "grafana_public_alb" {
  name        = "fargate_grafana_public_alb"
  vpc_id      = var.vpc_id
  description = "Grafana Internet-facing ALB"
}

data "aws_route53_zone" "public" {
  name = var.public_lb_domain_name
}

resource "aws_route53_record" "grafana_public_alb" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "grafana-ecs"
  type    = "A"

  alias {
    name                   = aws_lb.grafana_public.dns_name
    zone_id                = aws_lb.grafana_public.zone_id
    evaluate_target_health = true
  }
}
