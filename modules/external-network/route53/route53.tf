variable "hypo-driven_alb" {}

data "aws_route53_zone" "hypo-driven" {
  name = "hypo-driven.com"
}

resource "aws_route53_zone" "aws_hypo-driven" {
  name = "aws.hypo-driven.com"
}

resource "aws_route53_record" "hypo-driven" {
  name    = data.aws_route53_zone.hypo-driven.name
  type    = "A"
  zone_id = data.aws_route53_zone.hypo-driven.zone_id
  alias {
    evaluate_target_health = true
    name                   = var.hypo-driven_alb.hypo-driven_alb_name
    zone_id                = var.hypo-driven_alb.hypo-driven_alb_zone_id
  }
}

output "hypo-driven_aws_domain_name" {
  value = aws_route53_record.hypo-driven.name
}

output "hypo-driven_aws_zone_id" {
  value = aws_route53_zone.aws_hypo-driven.zone_id
}

