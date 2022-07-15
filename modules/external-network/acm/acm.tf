variable "hypo-driven_aws_domain_name" {}
variable "hypo-driven_aws_zone_id" {}

resource "aws_acm_certificate" "hypo-driven" {
  domain_name               = var.hypo-driven_aws_domain_name
  subject_alternative_names = []
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# for inspection of certificate
resource "aws_route53_record" "public_dns_verify" {
  for_each = {
    for dvo in aws_acm_certificate.hypo-driven.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = hypo-driven_aws_zone_id
}

resource "aws_acm_certificate_validation" "public" {
  certificate_arn         = aws_acm_certificate.hypo-driven.arn
  validation_record_fqdns = [for record in aws_route53_record.public_dns_verify : record.fqdn]
}

output "aws_hypo-driven_acm_arn" {
  value = aws_acm_certificate.hypo-driven.arn
}
