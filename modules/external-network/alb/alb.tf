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
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "this is HTTPS response"
      status_code = "200"
    }
  }
}

resource "aws_alb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_alb.hypo-driven.arn
  port = 8080
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port = 443
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }

}

output "hypo-driven_alb" {
  value = {
    hypo-driven_alb_name    = aws_alb.hypo-driven.dns_name
    hypo-driven_alb_zone_id = aws_alb.hypo-driven.zone_id
  }
}
