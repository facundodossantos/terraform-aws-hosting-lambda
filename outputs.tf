# ACM
output "acm_certificate_arn" {
  description = "The ARN of the ACM Certificate"
  value       = aws_acm_certificate.cert.arn
}

output "acm_certificate_id" {
  description = "The ARN of the ACM Certificate"
  value       = aws_acm_certificate.cert.id
}

# API Gateway
output "apigw_rest_api_id" {
  description = "The ID of the API Gateway Rest API"
  value       = try(aws_apigatewayv2_api.rest_api[0].id, null)
}

output "apigw_rest_api_arn" {
  description = "The ARN of the API Gateway Rest API"
  value       = try(aws_apigatewayv2_api.rest_api[0].arn, null)
}

output "apigw_rest_api_invoke_url" {
  description = "The URL to invoke the API pointing to the stage"
  value       = try(aws_apigatewayv2_stage.apigw_stage[0].invoke_url, null)
}

# Cloudfront
output "cf_distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cf_distribution.arn
}

output "cf_distribution_id" {
  description = "The identifier of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cf_distribution.id
}

output "cf_request_function_arn" {
  description = "The ARN of the CloudFront Function in charge of adding support for directory index documents."
  value       = aws_cloudfront_function.cf_function_request.arn
}

output "cf_response_function_arn" {
  description = "The ARN of the CloudFront Function in charge of supporting x-amz-website-redirect-location on objects."
  value       = aws_cloudfront_function.cf_function_response.arn
}

# Lambda
output "lambda_iam_role_id" {
  description = "The ID of the Lambda's IAM role."
  value       = try(aws_iam_role.lambda_role[0].id, null)
}

output "lambda_iam_role_arn" {
  description = "The ARN of the Lambda's IAM role."
  value       = try(aws_iam_role.lambda_role[0].arn, null)
}

output "lambda_arn" {
  description = "The ARN of the Lambda."
  value       = try(aws_lambda_function.lambda[0].arn, null)
}

# S3
output "s3_bucket_arn" {
  description = "The ARN of the S3 Bucket"
  value       = aws_s3_bucket.bucket.arn
}

output "s3_bucket_id" {
  description = "The ID of the S3 Bucket"
  value       = aws_s3_bucket.bucket.id
}
