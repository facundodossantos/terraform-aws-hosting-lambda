locals {
  domain_zone_ids = {
    for i, v in var.domains : v => element(var.zone_ids, index(var.domains, v))
  }
}

# Domain Validation Records
resource "aws_route53_record" "r53_domain_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      zone_id = element(var.zone_ids, index(var.domains, dvo.domain_name))
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

# Actual Records
resource "aws_route53_record" "r53_a" {
  for_each = aws_cloudfront_distribution.cf_distribution.enabled ? local.domain_zone_ids : {}

  allow_overwrite = true

  name = each.key
  type = "A"

  alias {
    name                   = replace(aws_cloudfront_distribution.cf_distribution.domain_name, "/[.]$/", "")
    zone_id                = aws_cloudfront_distribution.cf_distribution.hosted_zone_id
    evaluate_target_health = true
  }

  zone_id = each.value
}

resource "aws_route53_record" "r53_aaaa" {
  for_each = aws_cloudfront_distribution.cf_distribution.enabled && var.is_ipv6_enabled ? local.domain_zone_ids : {}

  allow_overwrite = true

  name = each.key
  type = "AAAA"

  alias {
    name                   = replace(aws_cloudfront_distribution.cf_distribution.domain_name, "/[.]$/", "")
    zone_id                = aws_cloudfront_distribution.cf_distribution.hosted_zone_id
    evaluate_target_health = true
  }

  zone_id = each.value
}
