locals {
  lambda_type = (var.lambda_image_config.image_uri != "" ? "container" : (var.lambda_package_config.filename != "" ? "package" : "none"))
  has_lambda  = local.lambda_type != "none"

  # Package Locales
  lambda_source_hash = local.lambda_type == "package" ? filebase64sha256(var.lambda_package_config.filename) : null
  is_lambda_using_s3 = local.lambda_type == "package" && var.lambda_package_config.s3_bucket != ""

  resolved_lambda_function_name = var.lambda_function_name != "" ? var.lambda_function_name : "${local.default_resource_prefix}-lambda"
  resolved_lambda_role_name     = var.lambda_role_name != "" ? var.lambda_role_name : "${local.default_resource_prefix}-lambda-role"
}

# Lambda Upload Package
resource "aws_s3_bucket_object" "lambda_zip_package" {
  count = local.is_lambda_using_s3 ? 1 : 0

  bucket = var.lambda_package_config.s3_bucket
  key    = var.lambda_package_config.s3_key

  source = var.lambda_package_config.filename
  etag   = filemd5(var.lambda_package_config.filename)
}

# Lambda Instance Role
data "aws_iam_policy_document" "lambda_iam_assume_policy" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  count = local.has_lambda ? 1 : 0

  name               = local.resolved_lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_iam_assume_policy.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_role_basic_exec_role" {
  count = local.has_lambda ? 1 : 0

  role       = aws_iam_role.lambda_role[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# CloudWatch
resource "aws_cloudwatch_log_group" "cloudwatch_group" {
  count = local.has_lambda ? 1 : 0

  name              = "/aws/lambda/${local.resolved_lambda_function_name}"
  retention_in_days = var.lambda_log_retention == -1 ? null : var.lambda_log_retention
}


# Lambda
resource "aws_lambda_function" "lambda" {
  count = local.has_lambda ? 1 : 0

  function_name = local.resolved_lambda_function_name
  role          = aws_iam_role.lambda_role[count.index].arn

  environment {
    variables = var.lambda_environment
  }

  architectures = length(var.lambda_architectures) > 0 ? var.lambda_architectures : null
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  package_type = local.lambda_type == "container" ? "Image" : "Zip"

  # Container Configuration
  image_uri = local.lambda_type == "container" ? var.lambda_image_config.image_uri : null
  dynamic "image_config" {
    for_each = local.lambda_type == "container" ? ["image_config"] : []
    content {
      command           = length(var.lambda_image_config.command) > 0 ? var.lambda_image_config.command : null
      entry_point       = length(var.lambda_image_config.entry_point) > 0 ? var.lambda_image_config.entry_point : null
      working_directory = var.lambda_image_config.working_directory != "" ? var.lambda_image_config.working_directory : null
    }
  }

  # Zip Configuration
  handler = local.lambda_type == "package" && var.lambda_package_config.handler != "" ? var.lambda_package_config.handler : null
  runtime = local.lambda_type == "package" && var.lambda_package_config.runtime != "" ? var.lambda_package_config.runtime : null

  filename         = local.lambda_type != "package" || local.is_lambda_using_s3 ? null : var.lambda_package_config.filename
  source_code_hash = local.lambda_source_hash

  s3_bucket = local.is_lambda_using_s3 ? var.lambda_package_config.s3_bucket : null
  s3_key    = local.is_lambda_using_s3 ? var.lambda_package_config.s3_key : null

  tags = var.tags

  depends_on = [
    aws_s3_bucket_object.lambda_zip_package,
    aws_cloudwatch_log_group.cloudwatch_group,
    aws_iam_role.lambda_role
  ]

  # VPC Configuration
  dynamic "vpc_config" {
    for_each = length(var.lambda_subnet_ids) > 0 ? ["vpc_config"] : []
    content {
      security_group_ids = var.lambda_security_group_ids
      subnet_ids         = var.lambda.subnet_ids
    }
  }
}