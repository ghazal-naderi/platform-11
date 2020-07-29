provider "aws" {}

variable "environment" {
  default = "dev"
}

variable "project" {
  default = "my"
}


resource "aws_kms_key" "logs" {
  description             = "This key is used to encrypt the logs bucket for ${var.project}/${var.environment}"
  deletion_window_in_days = 30
}

resource "aws_s3_bucket_public_access_block" "logs-block" {
  bucket = aws_s3_bucket.logs.id

  restrict_public_buckets = true
  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true
}

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.project}-${var.environment}-logs"
  force_destroy = false
  acl = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.logs.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  versioning {
    enabled = true
  }
}
