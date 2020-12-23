# Security group rules for controlling traffic in/out of GOV.UK Monitoring
# microservices are defined here.
#
# Naming: please use the following conventions where appropriate:
# For ingress rules:
#   Name: {destination}_from_{source}_{protocol}
#   Description: {destination} accepts requests from {source} over {protocol}
# For egress rules:
#   Name: {source}_to_{destination}_{protocol}
#   Description: {source} sends requests to {destination} over {protocol}

resource "aws_security_group_rule" "grafana_to_any_any" {
  description       = "Grafana sends requests to anywhere over any protocol"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.grafana.security_group_id
}

resource "aws_security_group_rule" "grafana_from_alb_http" {
  description              = "Grafana receives requests from its public ALB over HTTP"
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = module.grafana.security_group_id
  source_security_group_id = aws_security_group.grafana_public_alb.id
}

resource "aws_security_group_rule" "grafana_alb_from_office_https" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id = aws_security_group.grafana_public_alb.id
  cidr_blocks       = var.office_cidrs_list
}

resource "aws_security_group_rule" "grafana_alb_to_any_any" {
  type      = "egress"
  protocol  = "-1"
  from_port = 0
  to_port   = 0

  security_group_id = aws_security_group.grafana_public_alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}
