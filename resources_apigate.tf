locals {
  resolved_apigw_name = var.apigw_name != "" ? var.apigw_name : "${local.default_resource_prefix}-rest"
}

resource "aws_apigatewayv2_api" "rest_api" {
  count = local.has_lambda ? 1 : 0

  name        = local.resolved_apigw_name
  description = "${local.main_domain} (Terraform Managed)"

  protocol_type = "HTTP"

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  count = local.has_lambda ? 1 : 0

  api_id = aws_apigatewayv2_api.rest_api[count.index].id

  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.lambda[count.index].invoke_arn

  timeout_milliseconds = var.lambda_timeout * 1000
}


resource "aws_apigatewayv2_route" "lambda_route" {
  count = local.has_lambda ? 1 : 0

  api_id    = aws_apigatewayv2_api.rest_api[count.index].id
  route_key = "ANY /{proxy+}"

  target = format("integrations/%s", aws_apigatewayv2_integration.lambda[count.index].id)
}

resource "aws_apigatewayv2_stage" "apigw_stage" {
  count = local.has_lambda ? 1 : 0

  api_id      = aws_apigatewayv2_api.rest_api[count.index].id
  name        = var.apigw_stage
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 5
    throttling_rate_limit  = 50
  }

  tags = var.tags
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  count = local.has_lambda ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = format("%s/*/*", aws_apigatewayv2_api.rest_api[count.index].execution_arn)
}
