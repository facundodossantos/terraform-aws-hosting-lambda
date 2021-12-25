locals {
  main_domain               = var.domains[0]
  subject_alternative_names = length(var.domains) == 1 ? [] : slice(var.domains, 1, length(var.domains))
}

resource "aws_acm_certificate" "cert" {
  domain_name               = local.main_domain
  subject_alternative_names = local.subject_alternative_names

  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.r53_domain_validation_record : record.fqdn]
}
