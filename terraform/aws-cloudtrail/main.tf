data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
provider "aws" {}

variable "project" {
  default = "my"
}

variable "environment" {
  default = "dev"
}

resource "aws_cloudtrail" "audit" {
  depends_on                    = [aws_s3_bucket_policy.audit-policy]
  name                          = "${var.project}-audit-trail"
  s3_bucket_name                = aws_s3_bucket.audit.id
  s3_key_prefix                 = "audit"
  kms_key_id                    = aws_kms_key.audit.arn
  enable_log_file_validation    = true
  include_global_service_events = true
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
}

resource "aws_kms_key" "audit" {
  description             = "This key is used to encrypt the audit bucket"
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
        "Sid": "Allow CloudTrail to encrypt logs",
        "Effect": "Allow",
        "Principal": {"Service": ["cloudtrail.amazonaws.com"]},
        "Action": "kms:GenerateDataKey*",
        "Resource": "*",
        "Condition": {"StringLike": {"kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"}}
     },
    {
        "Sid": "Allow CloudTrail to describe key",
        "Effect": "Allow",
        "Principal": {"Service": ["cloudtrail.amazonaws.com"]},
        "Action": "kms:DescribeKey",
        "Resource": "*"
    },
    {
        "Sid": "Allow principals in the account to decrypt log files",
        "Effect": "Allow",
        "Principal": {"AWS": "*"},
        "Action": [
            "kms:Decrypt",
            "kms:ReEncryptFrom"
        ],
        "Resource": "*",
        "Condition": {
            "StringEquals": {"kms:CallerAccount": "${data.aws_caller_identity.current.account_id}"},
            "StringLike": {"kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"}
      }
    },
    {
      "Sid": "Allow log group to encrypt logs",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.${data.aws_region.current.name}.amazonaws.com"
      },
      "Action": [ 
         "kms:GenerateDataKey*",
         "kms:Encrypt*",
         "kms:Decrypt*",
         "kms:ReEncrypt*",
         "kms:Describe*"
    ],
      "Resource": "*",
      "Condition": {
                "ArnLike": {
                    "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"
                }
        }
      }
  ]
}
POLICY
}


resource "aws_s3_bucket_public_access_block" "audit-block" {
  bucket = aws_s3_bucket.audit.id

  restrict_public_buckets = true
  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true
}

resource "aws_s3_bucket_policy" "audit-policy" {
  bucket = aws_s3_bucket.audit.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.audit.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.audit.arn}/audit/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "AllowSSLRequestsOnly",
            "Action": "s3:*",
            "Effect": "Deny",
            "Resource": [
                "arn:aws:s3:::${var.project}-audit-trail",
                "arn:aws:s3:::${var.project}-audit-trail/*"
            ],
            "Condition": {
                "Bool": {
                     "aws:SecureTransport": "false"
                }
            },
           "Principal": "*"
        }
    ]
}
POLICY
}

data "aws_s3_bucket" "logs" {
  bucket = "${var.project}-${var.environment}-logs"
}



resource "aws_s3_bucket" "audit" {
  bucket        = "${var.project}-audit-trail"
  force_destroy = false
  acl           = "private"
  depends_on    = [data.aws_s3_bucket.logs]
  logging {
    target_bucket = data.aws_s3_bucket.logs.id
    target_prefix = "log/"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.audit.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
  versioning {
    enabled = true
  }
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name = "${var.project}_cloudtrail"

  retention_in_days = 0
  kms_key_id        = aws_kms_key.audit.arn
}


resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name = "${var.project}_cloudtrail-to-cloudwatch"

  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role_policy_document.json
}

data "aws_iam_policy_document" "cloudtrail_assume_role_policy_document" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "cloudtrail_role_policy" {
  name = "cloudtrail-role-policy"
  role = aws_iam_role.cloudtrail_to_cloudwatch.id

  policy = data.aws_iam_policy_document.cloudtrail_role_policy_document.json
}

data "aws_iam_policy_document" "cloudtrail_role_policy_document" {
  statement {
    sid       = "AWSCloudTrailCreateLogStream"
    actions   = ["logs:CreateLogStream"]
    resources = [aws_cloudwatch_log_group.cloudtrail.arn]
  }
  statement {
    sid       = "AWSCloudTrailPutLogEvents"
    actions   = ["logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_group.cloudtrail.arn]
  }
}

resource "aws_sns_topic" "security_alerts" {
  name              = "security-alerts-topic"
  display_name      = "Security Alerts"
  kms_master_key_id = "alias/aws/sns"

}

resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "root-access"
  pattern        = "{$.userIdentity.type = Root}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "RootAccessCount"
    namespace = "CloudTrail"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_login" {
  alarm_name          = "root-access-${data.aws_region.current.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootAccessCount"
  namespace           = "CloudTrail"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Use of the root account has been detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name           = "IAMPolicyChanges"
  pattern        = <<EOF
 "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}" 
EOF
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "IAMPolicyEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes" {
  alarm_name          = "security_group_changes-${data.aws_region.current.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAMPolicyEventCount"
  namespace           = "CloudTrailMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "IAM policy changes has been detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name           = "SecurityGroupEvents"
  pattern        = <<EOF
"{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
EOF
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "SecurityGroupEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_group_changes" {
  alarm_name          = "security_group_changes-${data.aws_region.current.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "SecurityGroupEventCount"
  namespace           = "CloudTrailMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Security group changes has been detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}


resource "aws_cloudwatch_log_metric_filter" "console_signin_failures" {
  name           = "ConsoleSignInFailures"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "ConsoleSigninFailureCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_signin_failures" {
  alarm_name          = "console_signin_failures-${data.aws_region.current.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ConsoleSigninFailureCount"
  namespace           = "CloudTrailMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "A console_signin_failures has been detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

resource "aws_cloudwatch_log_metric_filter" "network_acl_events" {
  name           = "NetworkACLEvents"
  pattern        = <<EOF
"{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
EOF    
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "NetworkACLEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "network_acl_events" {
  alarm_name          = "network_acl_events-${data.aws_region.current.name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NetworkACLEventCount"
  namespace           = "CloudTrailMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "A network_acl_events changes has been detected"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
}

