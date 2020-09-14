provider "aws" {
  version = "~> 2.0"
}

variable "domain" {
  default = "fakebank.com"
}

resource "aws_ses_domain_identity" "myid" {
  domain = var.domain
}

resource "aws_iam_user" "ses-smtp" {
  name = "ses-smtp-user"
}

resource "aws_iam_access_key" "access" {
  user = aws_iam_user.ses-smtp.name
}

resource "aws_iam_user_policy" "ses-smtp" {
  name = "AmazonSesSendingAccess"
  user = aws_iam_user.ses-smtp.name
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

resource "aws_iam_access_key" "ses-smtp" {
  user    = aws_iam_user.ses-smtp.name
}

output "aws_ses_smtp_password" {
value = aws_iam_access_key.access.ses_smtp_password_v4
}

output "domain_verification" { 
value = aws_ses_domain_identity.myid.verification_token
}
