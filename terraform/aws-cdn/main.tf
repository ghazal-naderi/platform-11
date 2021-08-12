data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
provider "aws" {}

provider "aws" {
  alias = "useast"
  region = "us-east-1"
}

variable "subdomain" {
  default = "assets"
}

variable "zone" {
  default = "dev.fakebank.com"
}

variable "project" {
  default = "my"
}

variable "environment" {
  default = "int"
}

variable "bucket" {
  default = "assets.int"
}

data "aws_route53_zone" "parent" {
  name = "${var.zone}."
}

resource "aws_s3_bucket" "cdn-logs" {
  bucket = "${var.project}-${var.environment}-cdn-logs"
  acl    = "log-delivery-write"
  versioning {
    enabled = true
  }
 server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cdn-logs-block" {
  bucket = aws_s3_bucket.cdn-logs.id

  restrict_public_buckets = true
  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true
}

resource "aws_route53_record" "assets" {
  zone_id = data.aws_route53_zone.parent.zone_id
  name    = "${var.subdomain}.${var.environment}.${var.zone}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  for_each = {
  }
  provider = aws.useast
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation[each.key].fqdn]
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "${var.subdomain}.${var.environment}.${var.zone}"
  provider = aws.useast
  validation_method = "DNS"

  tags = {
    Environment = "${var.environment}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  zone_id         = data.aws_route53_zone.parent.zone_id
  ttl             = 60
  type            = each.value.type
}

resource "aws_s3_bucket_policy" "b" {
  bucket = aws_s3_bucket.b.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "S3AllowCFOAI",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "${aws_cloudfront_origin_access_identity.default.iam_arn}" },
      "Action": "s3:GetObject*",
      "Resource": "${aws_s3_bucket.b.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_public_access_block" "b" {
  bucket = aws_s3_bucket.b.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "cnd-key" {
  description             = "This key is used to encrypt the b  bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        ]
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Enable Access to the key for cloudfront service",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "cloudfront.amazonaws.com"
        ]
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY
}
resource "aws_s3_bucket" "b" {
  bucket        = "${var.bucket}.${var.zone}"
  acl           = "private"
  force_destroy = true

  tags = {
    Name        = "Assets bucket"
    Environment = "${var.environment}"
  }
   versioning {
    enabled = true
  }
  logging {
    target_bucket = aws_s3_bucket.cdn-logs.id
    target_prefix = "log/cdn/"
  }
 server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "default" {
  comment = "CF Origin Access Identity for Assets"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    origin_id   = "${var.bucket}.${var.zone}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
    }
  }
  logging_config {
    include_cookies = false
    bucket          = "${var.project}-${var.environment}-cdn-logs.s3.amazonaws.com"
    prefix          = "cdn_s3_distribution"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  aliases             = ["${var.subdomain}.${var.environment}.${var.zone}"]
  price_class         = "PriceClass_100"
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Assets"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.bucket}.${var.zone}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 60
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  tags = {
    Environment = "${var.environment}"
    Application = "CDN"
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }
}

output "bucket_id" {
  value = aws_s3_bucket.b.id
}
