locals {
  s3_origin_id             = "S3Website-${local.resolved_bucket_name}"
  lambda_origin_id         = "Lambda-${local.resolved_lambda_function_name}"
  resolved_cf_s3_secret_ua = var.cf_s3_secret_ua != "" ? var.cf_s3_secret_ua : "CloudFront_${random_uuid.random_uuid[0].result}"
}

# Secet Key (if needed)
resource "random_uuid" "random_uuid" {
  count = var.cf_s3_secret_ua == "" ? 1 : 0
}

resource "aws_cloudfront_distribution" "cf_distribution" {
  enabled         = var.is_cloudfront_enabled
  is_ipv6_enabled = var.is_ipv6_enabled

  comment = "${local.main_domain} (Terraform Managed)"
  tags    = var.tags

  price_class = "PriceClass_100"

  aliases = var.domains

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]
    cached_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]

    compress = true

    min_ttl     = var.cache_min_ttl
    default_ttl = var.cache_default_ttl
    max_ttl     = var.cache_max_ttl

    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  origin {
    origin_id   = local.s3_origin_id
    domain_name = aws_s3_bucket.bucket.website_endpoint

    custom_header {
      name  = "User-Agent"
      value = local.resolved_cf_s3_secret_ua
    }

    custom_origin_config {
      http_port  = 80
      https_port = 443

      origin_protocol_policy = "http-only"
      origin_ssl_protocols = [
        "TLSv1.2"
      ]
    }
  }

  dynamic "origin" {
    for_each = local.has_lambda ? ["lambda_origin"] : []
    content {
      origin_id = local.lambda_origin_id

      domain_name = regex("^https://([^/]+)/.+$", aws_apigatewayv2_stage.apigw_stage[0].invoke_url)[0]

      custom_origin_config {
        http_port  = 80
        https_port = 443

        origin_protocol_policy = "https-only"
        origin_ssl_protocols = [
          "TLSv1.2"
        ]

        origin_read_timeout = var.lambda_timeout
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = local.has_lambda ? ["lambda_origin"] : []
    content {
      path_pattern = format("%s/*", regex("^https://[^/]+/(.+)$", aws_apigatewayv2_stage.apigw_stage[0].invoke_url)[0])

      allowed_methods = [
        "DELETE",
        "GET",
        "HEAD",
        "OPTIONS",
        "PATCH",
        "POST",
        "PUT"
      ]
      cached_methods = [
        "GET",
        "HEAD",
        "OPTIONS",
      ]

      compress = true

      min_ttl     = var.cache_min_ttl
      default_ttl = var.cache_default_ttl
      max_ttl     = var.cache_max_ttl

      target_origin_id       = local.lambda_origin_id
      viewer_protocol_policy = "redirect-to-https"

      forwarded_values {
        query_string = true

        headers = [
          "Access-Control-Request-Headers",
          "Access-Control-Request-Method",
          "Authorization",
          "Origin",
        ]

        cookies {
          forward = "none"
        }
      }
    }
  }

  dynamic "logging_config" {
    for_each = var.cf_logging_config.bucket != "" ? ["logging_config"] : []
    content {
      bucket = "${var.cf_logging_config.bucket}.s3.amazonaws.com"
      prefix = var.cf_logging_config.prefix != "" ? var.cf_logging_config.prefix : null

      include_cookies = var.cf_logging_config.include_cookies
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    minimum_protocol_version = var.cf_minimum_protocol_version
    ssl_support_method       = "sni-only"
  }
}