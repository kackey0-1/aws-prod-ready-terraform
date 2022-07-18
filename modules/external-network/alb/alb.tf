variable "vpc_id" {}
variable "public_subnets" {}
variable "access_log_bucket_id" {}
variable "aws_hypo-driven_acm_arn" {}

resource "aws_alb" "hypo-driven" {
  name                             = "hypo-driven"
  load_balancer_type               = "application"
  internal                         = false
  idle_timeout                     = 60
  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true
  subnets                          = [
    var.public_subnets.public_subnet_0,
    var.public_subnets.public_subnet_1
  ]

  access_logs {
    bucket  = var.access_log_bucket_id
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id
  ]
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

module "http_sg" {
  source      = "../../internal-network/security_group"
  name        = "http_sg"
  vpc_id      = var.vpc_id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "../../internal-network/security_group"
  name        = "https_sg"
  vpc_id      = var.vpc_id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "../../internal-network/security_group"
  name        = "http_redirect_sg"
  vpc_id      = var.vpc_id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

output "hypo-driven_alb" {
  value = {
    hypo-driven_alb_name    = aws_alb.hypo-driven.dns_name
    hypo-driven_alb_zone_id = aws_alb.hypo-driven.zone_id
  }
}
