provider "aws" {}

data "aws_caller_identity" "current" {}

variable "domain" {
  default = "fakebank.com"
}

variable "manual_domain_verification" {
  description = "If set to false,do not create aws_route53_zone and verificate domain manually"
  type        = bool
  default = false
}

resource "aws_ses_domain_identity" "myid" {
  domain = var.domain
}

data "aws_route53_zone" "myid" {
  name         = var.domain
  count = var.manual_domain_verification ? 1 : 0  
}

resource "aws_route53_record" "myid_amazonses_verification_record" {
  count = var.manual_domain_verification ? 1 : 0
  zone_id = data.aws_route53_zone.myid[count.index].zone_id
  name    = "_amazonses.${aws_ses_domain_identity.myid.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.myid.verification_token]
}

resource "aws_ses_domain_identity_verification" "myid_verification" {
  domain = var.domain
  count = var.manual_domain_verification ? 1 : 0

  depends_on = [aws_route53_record.myid_amazonses_verification_record]
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda_access"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
        ]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.cwd}/lambda_ses"
  output_path = "payload.zip"
}

resource "aws_lambda_function" "ses_stream_slack" {
  filename         = "payload.zip"
  function_name    = "ses_stream_slack"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda.lambda_handler"
  publish          = true
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.6"
}

module "stream_bounces" {
  source = "./stream"
  type   = "Bounce"
  domain = var.domain
  lambda = aws_lambda_function.ses_stream_slack.arn
}
module "stream_complaints" {
  source = "./stream"
  type   = "Complaint"
  domain = var.domain
  lambda = aws_lambda_function.ses_stream_slack.arn
}
module "stream_deliveries" {
  source = "./stream"
  type   = "Delivery"
  domain = var.domain
  lambda = aws_lambda_function.ses_stream_slack.arn
}

resource "aws_iam_user" "ses-smtp" {
  name = "ses-smtp-user"
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_iam_user_policy" "ses-smtp" {
  name = "AmazonSesSendingAccess"
  user = aws_iam_user.ses-smtp.name
  lifecycle {
    ignore_changes = all
  }
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ses:SendRawEmail",
            "Resource": "*"
        }
    ]
}
EOF
}

output "domain_verification" {
  value = aws_ses_domain_identity.myid.verification_token
}
