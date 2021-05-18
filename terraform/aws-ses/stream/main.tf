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
  name = "ses_${lower(var.type)}_dead_letter_queue"
  kms_master_key_id         = "alias/aws/sqs"
}

resource "aws_sns_topic" "ses_topic" {
  name              = "ses_${lower(var.type)}_topic"
  kms_master_key_id = "alias/aws/sns"
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
