variable "domains" {
  description = "List of domains for which the CloudFront Distribution will be serving files."
  type        = list(string)

  validation {
    condition     = length(var.domains) >= 1
    error_message = "You must specify at least one domain name in the list."
  }

  validation {
    condition     = length(var.domains) == length(toset(var.domains))
    error_message = "Values in the list must be unique."
  }
}

variable "zone_ids" {
  description = "List of Route53 zone IDs for the domains specified in var.domains"
  type        = list(string)
}

# Bucket Configuration
variable "bucket_name" {
  description = "S3 bucket name used to deploy the website resources on. If left empty, defaults to using the first domain as name."
  type        = string
  default     = ""
}

variable "bucket_force_destroy" {
  description = "Allow Terraform to destroy the bucket even if there are objects within."
  type        = bool
  default     = false
}

variable "index_document" {
  description = "Filename of the index document to be used in the bucket."
  type        = string
  default     = "index.html"

  validation {
    condition     = length(var.index_document) > 0
    error_message = "Value cannot be empty."
  }
}

variable "error_document" {
  description = "Filename of the error document to be used in the bucket."
  type        = string
  default     = "error.html"

  validation {
    condition     = length(var.error_document) > 0
    error_message = "Value cannot be empty."
  }
}

# CloudFont Parameters
variable "is_cloudfront_enabled" {
  description = "Allows disabling the CloudFront distribution. Note that records will be deleted if CF is disabled."
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Toggles if IPv6 is enabled on the CloudFront distribution. If enabled, it will automatically create relevant AAAA records."
  type        = bool
  default     = true
}

variable "cf_logging_config" {
  description = "Provides logging configuration for the CloudFront distribution"
  type = object({
    bucket          = string
    include_cookies = bool
    prefix          = string
  })
  default = {
    bucket          = ""
    include_cookies = false
    prefix          = ""
  }
}

variable "cf_price_class" {
  description = "CloudFront Price Class"
  type        = string
  default     = "PriceClass_All"
}

variable "cf_minimum_protocol_version" {
  description = "CloudFront SSL/TLS Minimum Protocol Version"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "cf_website_origin_id" {
  description = "CloudFront origin id that will be used for the origin pointing to the API gateway. Will be automatically generated if empty."
  type        = string
  default     = ""
}

variable "cf_website_cache_policy_id" {
  description = "Cache Policy Id to apply to the default (S3 bucket) cache behavior of the CloudFront distribution. Defaults to 'Managed-CachingOptimized'"
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

variable "cf_website_origin_request_policy_id" {
  description = "Origin Request Policy Id to apply to the default (S3 bucket) cache behavior of the CloudFront distribution. Defaults to 'Managed-CORS-S3Origin'. Leave empty for none."
  type        = string
  default     = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
}

variable "cf_website_response_headers_policy_id" {
  description = "Response Headers Policy Id to apply to the default (S3 bucket) cache behavior of the CloudFront distribution. Defaults to none. Leave empty for none."
  type        = string
  default     = ""
}

variable "cf_lambda_origin_id" {
  description = "CloudFront origin id that will be used for the origin pointing to the API gateway. Will be automatically generated if empty."
  type        = string
  default     = ""
}

variable "cf_lambda_cache_policy_id" {
  description = "Cache Policy Id to apply to the Lambda cache behavior of the CloudFront distribution. Defaults to 'Managed-CachingDisabled'"
  type        = string
  default     = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}

variable "cf_lambda_origin_request_policy_id" {
  description = "Origin Request Policy Id to apply to the Lambda cache behavior of the CloudFront distribution. Defaults to 'Managed-Elemental-MediaTailor-PersonalizedManifests'. Leave empty for none."
  type        = string
  default     = "775133bc-15f2-49f9-abea-afb2e0bf67d2"
}

variable "cf_lambda_response_headers_policy_id" {
  description = "Response Headers Policy Id to apply to the Lambda cache behavior of the CloudFront distribution. Defaults to none. Leave empty for none."
  type        = string
  default     = ""
}

variable "cf_s3_secret_ua" {
  description = "Secret User-Agent used to prevent everyone but CloudFront from accessing the S3 Website Endpoint. If empty, a value will be automatically generated for you."
  type        = string
  default     = ""
}

variable "cf_custom_origins" {
  description = "List of additional custom origins for which to selectively route traffic to."
  type = list(object({
    origin_id   = string
    domain_name = string
    custom_headers = list(object({
      name  = string
      value = string
    }))
    custom_origin_config = object({
      http_port              = number
      https_port             = number
      origin_protocol_policy = string
      origin_ssl_protocols   = list(string)
      origin_read_timeout    = number
    })
  }))
  default = []
}

variable "cf_custom_behaviors" {
  description = "List of additional CloudFront behaviors."
  type = list(object({
    target_origin_id           = string
    path_pattern               = string
    allowed_methods            = list(string)
    cached_methods             = list(string)
    compress                   = bool
    viewer_protocol_policy     = string
    cache_policy_id            = string
    origin_request_policy_id   = string
    response_headers_policy_id = string
  }))
  default = []
}

# AWS Lambda Variables
variable "lambda_function_name" {
  description = "Name of the Lambda function. If left empty, a value will be derived from the first domain name."
  type        = string
  default     = ""
}

variable "lambda_role_name" {
  description = "Name of IAM role to create for the Lambda function. If left empty, a value will be derived from the first domain name."
  type        = string
  default     = ""
}

variable "lambda_environment" {
  description = "Environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "lambda_architectures" {
  description = "Instruction set architecture for your Lambda function."
  type        = list(string)
  default     = []
}

variable "lambda_image_config" {
  description = "If using a container Lambda, provides image configuration options"
  type = object({
    image_uri         = string
    command           = list(string)
    entry_point       = list(string)
    working_directory = string
  })
  default = {
    image_uri         = ""
    command           = []
    entry_point       = []
    working_directory = ""
  }
}

variable "lambda_package_config" {
  description = "If using a traditional Lambda, provides runtime and package options"
  type = object({
    filename  = string
    runtime   = string
    handler   = string
    s3_bucket = string
    s3_key    = string
  })
  default = {
    filename  = ""
    s3_bucket = ""
    s3_key    = ""
    runtime   = "provided"
    handler   = ""
  }
}

variable "lambda_memory_size" {
  description = "mount of memory in MB your Lambda Function can use at runtime."
  type        = number
  default     = 128

  validation {
    condition     = var.lambda_memory_size >= 0 && floor(var.lambda_memory_size) == var.lambda_memory_size
    error_message = "Value must be a positive integer."
  }
}

variable "lambda_log_retention" {
  description = "Amount of days the lambda logs are retained. Use -1 to leave the default value."
  type        = number
  default     = -1
}

variable "lambda_timeout" {
  description = "Amount of time your Lambda Function has to run in seconds."
  type        = number
  default     = 3

  validation {
    condition     = var.lambda_timeout >= 0 && var.lambda_timeout <= 29 && floor(var.lambda_timeout) == var.lambda_timeout
    error_message = "Value must be a positive integer up to 29 seconds."
  }
}

variable "lambda_subnet_ids" {
  description = "List of subnets IDs associated with the lambda function"
  type        = list(string)
  default     = []
}

variable "lambda_security_group_ids" {
  description = "List of security group IDs associated with the lambda function. Only valid if subnets are specified."
  type        = list(string)
  default     = []
}

# API Gateway Variables
variable "apigw_name" {
  description = "Name of the API Gateway Rest API. If left empty, a value will be derived from the first domain name."
  type        = string
  default     = ""
}

variable "apigw_stage" {
  description = "Name of the API Gateway Rest Stage."
  type        = string
  default     = "api"
}

variable "apigw_payload_format_version" {
  description = "The format of the payload sent to the lambda."
  type        = string
  default     = "1.0"
}

variable "apigw_throttling_burst_limit" {
  description = "The throttling burst limit for the route."
  type        = number
  default     = 5

  validation {
    condition     = var.apigw_throttling_burst_limit >= 0 && floor(var.apigw_throttling_burst_limit) == var.apigw_throttling_burst_limit
    error_message = "Value must be a positive integer."
  }
}

variable "apigw_throttling_rate_limit" {
  description = "The throttling rate limit for the route.."
  type        = number
  default     = 50

  validation {
    condition     = var.apigw_throttling_rate_limit >= 0 && floor(var.apigw_throttling_rate_limit) == var.apigw_throttling_rate_limit
    error_message = "Value must be a positive integer."
  }
}

# General Variables
variable "tags" {
  description = "AWS tags to apply to every resource created by this module"
  type        = map(string)
  default     = {}
}
