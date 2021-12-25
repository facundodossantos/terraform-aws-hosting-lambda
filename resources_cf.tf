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

  dynamic "origin" {
    for_each = toset(var.cf_custom_origins)
    content {
      origin_id = format("CustomTFOrigin-%04d", index(var.cf_custom_origins, origin.value) + 1)

      domain_name = origin.value.domain_name

      dynamic "custom_header" {
        for_each = toset(origin.value.custom_headers)
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      custom_origin_config {
        http_port  = origin.value.custom_origin_config.http_port
        https_port = origin.value.custom_origin_config.https_port

        origin_protocol_policy = origin.value.custom_origin_config.origin_protocol_policy
        origin_ssl_protocols   = origin.value.custom_origin_config.origin_ssl_protocols

        origin_read_timeout = origin.value.custom_origin_config.origin_read_timeout
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

  dynamic "ordered_cache_behavior" {
    for_each = toset(var.cf_custom_origins)
    content {
      path_pattern = ordered_cache_behavior.value.path_pattern

      allowed_methods = ordered_cache_behavior.value.allowed_methods
      cached_methods  = ordered_cache_behavior.value.cached_methods

      compress = ordered_cache_behavior.value.compress

      min_ttl     = ordered_cache_behavior.value.min_ttl
      default_ttl = ordered_cache_behavior.value.default_ttl
      max_ttl     = ordered_cache_behavior.value.max_ttl

      target_origin_id       = format("CustomTFOrigin-%04d", index(var.cf_custom_origins, ordered_cache_behavior.value) + 1)
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy

      forwarded_values {
        query_string            = ordered_cache_behavior.value.forwarded_values.query_string
        query_string_cache_keys = length(ordered_cache_behavior.value.forwarded_values.query_string_cache_keys) > 0 ? ordered_cache_behavior.value.forwarded_values.query_string_cache_keys : null

        headers = ordered_cache_behavior.value.forwarded_values.headers

        cookies {
          forward           = ordered_cache_behavior.value.forwarded_values.cookies.forward
          whitelisted_names = ordered_cache_behavior.value.forwarded_values.cookies.forward == "whitelist" ? ordered_cache_behavior.value.forwarded_values.cookies.whitelisted_names : null
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