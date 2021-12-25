locals {
  resolved_bucket_name = var.bucket_name == "" ? local.main_domain : var.bucket_name
}

# Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = local.resolved_bucket_name
  acl    = "private"

  website {
    index_document = var.index_document
    error_document = var.error_document
  }

  versioning {
    enabled = false
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      website["routing_rules"],
    ]
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket Access Policy
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "CloudFrontPublicRead"

    actions = [
      "s3:GetObject"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:UserAgent"
      values   = ["{bucket_access_key}"]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = replace(
    data.aws_iam_policy_document.bucket_policy.json,
    "\"{bucket_access_key}\"",
    jsonencode(local.resolved_cf_s3_secret_ua)
  ) # Workaround as a data cannot depend on a resource

  depends_on = [aws_s3_bucket_public_access_block.bucket_public_access_block]
}
