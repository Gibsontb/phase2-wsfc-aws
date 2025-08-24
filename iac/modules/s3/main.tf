# Author: tgibson
variable "project" {
  type = string
}
variable "tags" {
  type = map(string)
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project}-artifacts-${random_string.suffix.result}"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.project}-logs-${random_string.suffix.result}"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-access-logs"
    status = "Enabled"

    # Required: exactly one of filter or prefix
    filter { prefix = "" }

    expiration { days = 90 }

    noncurrent_version_expiration { noncurrent_days = 30 }
  }
}

# --- ALB access logging permissions ---

# AWS service account that writes ALB logs in this region/account
data "aws_elb_service_account" "this" {}

# Allow ALB to list the bucket and write objects under the "alb-logs/" prefix
resource "aws_s3_bucket_policy" "logs_allow_alb_delivery" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.this.arn }
        Action    = ["s3:PutObject","s3:PutObjectAcl"]
        Resource  = "${aws_s3_bucket.logs.arn}/alb-logs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "AWSLogDeliveryList"
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.this.arn }
        Action    = "s3:ListBucket"
        Resource  = aws_s3_bucket.logs.arn
      }
    ]
  })
}

output "bucket_name"      { value = aws_s3_bucket.artifacts.bucket }
output "logs_bucket_name" { value = aws_s3_bucket.logs.bucket }
