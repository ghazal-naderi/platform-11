data "aws_caller_identity" "current" {}
variable "type" { default = "Bounce" }
variable "domain" { default = "11fs-structs.com" }
variable "lambda" {}
data "aws_iam_policy_document" "ses_queue_iam_policy" {
  policy_id = "SES${var.type}QueueTopic"
  statement {
    sid       = "SES${var.type}QueueTopic"
    effect    = "Allow"
    actions   = ["SQS:SendMessage"]
    resources = [aws_sqs_queue.ses_queue.arn]
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.ses_topic.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sns_topic_subscription" "topic_lambda" {
  topic_arn = aws_sns_topic.ses_topic.arn
  protocol  = "lambda"
  endpoint  = var.lambda
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNSTopic${lower(var.type)}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ses_topic.arn
}

resource "aws_sqs_queue_policy" "ses_policy" {
  queue_url = aws_sqs_queue.ses_queue.id
  policy    = data.aws_iam_policy_document.ses_queue_iam_policy.json
}

resource "aws_sqs_queue" "ses_queue" {
  name                      = "${lower(var.type)}_ses_queue"
  message_retention_seconds = 1209600
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.ses_dead_letter_queue.arn}\",\"maxReceiveCount\":4}"
  kms_master_key_id         = "alias/aws/sqs"
}
resource "aws_sqs_queue" "ses_dead_letter_queue" {
  name              = "ses_${lower(var.type)}_dead_letter_queue"
  kms_master_key_id = "alias/aws/sqs"
}

resource "aws_sns_topic" "ses_topic" {
  name              = "ses_${lower(var.type)}_topic"
  kms_master_key_id = aws_kms_key.sns_topic_key.key_id
}

resource "aws_kms_key" "sns_topic_key" {
  description             = "This key is used to encrypt the audit bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                   = data.aws_iam_policy_document.sns_topic_key_document.json
}

  data "aws_iam_policy_document" "sns_topic_key_document" {
    version = "2012-10-17"
    statement {
      sid    = "Allow access through SNS for all principals in the account that are authorized to use SNS"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      actions   = ["kms:*"]
      resources = ["*"]
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["arn:aws:cloudtrail:*:XXXXXXXXXXXX:trail/*"]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = ["arn:aws:cloudtrail:*:XXXXXXXXXXXX:trail/*"]
      }
    }
    statement {
      sid    = "Allow direct access to key metadata to the account"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      actions   = ["kms:*"]
      resources = ["*"]
    }
    statement {
      sid    = "AllowSESToUseKMSKey"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["ses.amazonaws.com"]
      }
      actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
      resources = ["*"]
    }
}

resource "aws_sns_topic_subscription" "ses_subscription" {
  topic_arn = aws_sns_topic.ses_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ses_queue.arn
}

resource "aws_ses_domain_identity" "ses_topic" {
  domain = var.domain
}

resource "aws_ses_identity_notification_topic" "ses" {
  topic_arn                = aws_sns_topic.ses_topic.arn
  notification_type        = var.type
  identity                 = aws_ses_domain_identity.ses_topic.domain
  include_original_headers = true
}
