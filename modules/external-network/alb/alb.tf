variable "public_subnets" {}
variable "access_log_bucket_id" {}
variable "alb_security_groups" {}
variable "aws_hypo-driven_acm_arn" {}

resource "aws_alb" "hypo-driven" {
  name                             = "hypo-driven"
  load_balancer_type               = "application"
  internal                         = false
  idle_timeout                     = 60
  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true
  subnets                          = var.public_subnets

  access_logs {
    bucket  = var.access_log_bucket_id
    enabled = true
  }

  security_groups = var.alb_security_groups
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.hypo-driven.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = var.aws_hypo-driven_acm_arn
  default_action {
    type = ""
  }
}

output "hypo-driven_alb" {
  value = {
    hypo-driven_alb_name    = aws_alb.hypo-driven.dns_name
    hypo-driven_alb_zone_id = aws_alb.hypo-driven.zone_id
  }
}
