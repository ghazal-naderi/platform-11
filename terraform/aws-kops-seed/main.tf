provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

variable "region" {
  default = "us-east-1"
}

variable "stack_name" {
  default = "mino-stage"
}

variable "environment" {
  default = "stage"
}

variable "project" {
  default = "gen6"
}

variable "zone_name" {
  default = "mino-stage.enva.gen6bk.com"
}

resource "aws_iam_user" "kops" {
  name = "kops"
  path = "/system/"
}

resource "aws_iam_access_key" "kops" {
  user = aws_iam_user.kops.name
}

resource "aws_iam_user_policy_attachment" "kops-ec2" {
  user       = aws_iam_user.kops.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_user_policy_attachment" "kops-53" {
  user       = aws_iam_user.kops.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_user_policy_attachment" "kops-s3" {
  user       = aws_iam_user.kops.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_user_policy_attachment" "kops-iam" {
  user       = aws_iam_user.kops.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_user_policy_attachment" "kops-vpc" {
  user       = aws_iam_user.kops.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_user_policy_attachment" "kops-bucket" {
  user       = aws_iam_user.kops.name
  policy_arn = aws_iam_policy.bucket.arn
}

resource "aws_kms_key" "bucketenckey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_public_access_block" "bucket-bolock" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.stack_name}-state"
  acl    = "private"
  versioning {
    enabled = true
  }
  tags = {
    Name        = "State store for ${var.stack_name}"
    Environment = var.environment
    Project     = var.project
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.bucketenckey.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_iam_policy" "bucket" {
  name        = "${var.stack_name}-state-bucket-policy"
  path        = "/"
  description = "Policy for Terraform/kops access to bucket ${var.stack_name}"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action":[
          "s3:ListAllMyBuckets"
      ],
      "Resource":"arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [ "s3:ListBucket", "s3:GetBucketLocation" ],
      "Resource": "${aws_s3_bucket.bucket.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [ "s3:GetObject", "s3:GetObjectAcl", "s3:GetObjectVersion", "s3:PutObject", "s3:PutObjectAcl" ],
      "Resource": "${aws_s3_bucket.bucket.arn}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ],
      "Resource": "${aws_kms_key.bucketenckey.arn}"
    }
  ]
}
EOF
}

resource "aws_route53_zone" "zone" {
  name = var.zone_name
}

locals {
  zone_name_list   = split(".", var.zone_name)
  parent_zone_name = join(".", slice(local.zone_name_list, 1, length(local.zone_name_list)))
}

data "aws_route53_zone" "parent_zone" {
  name = local.parent_zone_name
}

resource "aws_route53_record" "zone_record" {
  allow_overwrite = true
  name            = var.zone_name
  ttl             = 30
  type            = "NS"
  zone_id         = aws_route53_zone.zone.zone_id

  records = [
    aws_route53_zone.zone.name_servers.0,
    aws_route53_zone.zone.name_servers.1,
    aws_route53_zone.zone.name_servers.2,
    aws_route53_zone.zone.name_servers.3,
  ]
}

resource "aws_route53_record" "parent_zone_record" {
  allow_overwrite = true
  name            = var.zone_name
  ttl             = 30
  type            = "NS"
  zone_id         = data.aws_route53_zone.parent_zone.zone_id

  records = [
    aws_route53_zone.zone.name_servers.0,
    aws_route53_zone.zone.name_servers.1,
    aws_route53_zone.zone.name_servers.2,
    aws_route53_zone.zone.name_servers.3,
  ]
}

output "s3_kms" {
  value = aws_kms_key.bucketenckey.arn
}

output "s3_bucket" {
  value = aws_s3_bucket.bucket.arn
}

output "route53_zone" {
  value = aws_route53_zone.zone.zone_id
}

output "aws_access_key_id" {
  value = aws_iam_access_key.kops.id
}
output "aws_secret_access_key" {
  value = aws_iam_access_key.kops.secret
}
