provider "aws" {}

variable "aws_account_id" {}
variable "region" { default = "us-east-1" }

resource "aws_organizations_organization" "org" {
  aws_service_access_principals = ["guardduty.amazonaws.com"]
  feature_set                   = "ALL"
}

resource "aws_guardduty_detector" "detector" {
  enable = true
}

resource "aws_guardduty_organization_configuration" "config" {
  auto_enable = true
  detector_id = aws_guardduty_detector.detector.id
}


resource "aws_guardduty_organization_admin_account" "admin" {
  depends_on = [aws_organizations_organization.org]

  admin_account_id = var.aws_account_id
}


