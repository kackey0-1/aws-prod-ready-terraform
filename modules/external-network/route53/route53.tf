variable "hypo-driven_alb" {}


resource "aws_route53_record" "hypo-driven" {
  allow_overwrite = true
  name    = "aws.hypo-driven.com"
  ttl             = 172800
  type    = "NS"
  zone_id = "Z014287529AIE40PU4H85"
  records = [
    aws_route53_zone.aws_hypo-driven.name_servers[0],
    aws_route53_zone.aws_hypo-driven.name_servers[1],
    aws_route53_zone.aws_hypo-driven.name_servers[2],
    aws_route53_zone.aws_hypo-driven.name_servers[3],
  ]
}

resource "aws_route53_zone" "aws_hypo-driven" {
  name = "aws.hypo-driven.com"
}

resource "aws_route53_record" "aws_hypo-driven" {
  name    = aws_route53_zone.aws_hypo-driven.name
  type    = "A"
  zone_id = aws_route53_zone.aws_hypo-driven.zone_id
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

