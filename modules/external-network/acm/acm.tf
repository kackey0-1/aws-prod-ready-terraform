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
resource "aws_route53_record" "hypo-driven_certificate" {
  name    = aws_acm_certificate.hypo-driven.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.hypo-driven.domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.hypo-driven.domain_validation_options[0].resource_record_value]
  zone_id = var.hypo-driven_aws_zone_id
  ttl     = 60
}

resource "aws_acm_certificate_validation" "hypo-driven" {
  certificate_arn         = aws_acm_certificate.hypo-driven.arn
  validation_record_fqdns = [aws_route53_record.hypo-driven_certificate.fqdn]
}

output "aws_hypo-driven_acm_arn" {
  value = aws_acm_certificate.hypo-driven.arn
}
