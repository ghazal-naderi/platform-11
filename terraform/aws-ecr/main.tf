provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-2"
}

resource "aws_ecr_repository" "platform_infra_tester" {
  name                 = "platform/infra-tester"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "platform_infra_tester_rw_policy" {
  repository = aws_ecr_repository.platform_infra_tester.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "Allow IAM access for ECR user",
            "Effect": "Allow",
            "Principal": { "AWS": "${aws_iam_user.platform_docker_user_push.arn}" },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ]
        }
    ]
}
EOF
}

resource "aws_ecr_repository_policy" "platform_infra_tester_ro_policy" {
  repository = aws_ecr_repository.platform_infra_tester.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "Allow IAM access for ECR user",
            "Effect": "Allow",
            "Principal": { "AWS": "${aws_iam_user.platform_docker_user_pull.arn}" },
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_user_policy" "platform_ecr_authorization_push" {
  name = "platform_ecr_authorization_push"
  user = aws_iam_user.platform_docker_user_push.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": [ "*" ]
    }
  ]
}
EOF
}

resource "aws_iam_user_policy" "platform_ecr_authorization_pull" {
  name = "platform_ecr_authorization_pull"
  user = aws_iam_user.platform_docker_user_pull.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": [ "*" ]
    }
  ]
}
EOF
}

resource "aws_iam_user" "platform_docker_user_push" {
  name = "platform_docker_user_push"
  path = "/system/"
}

resource "aws_iam_access_key" "platform_docker_user_push_key" {
  user = aws_iam_user.platform_docker_user_push.name
}
resource "aws_iam_user" "platform_docker_user_pull" {
  name = "platform_docker_user_pull"
  path = "/system/"
}

resource "aws_iam_access_key" "platform_docker_user_pull_key" {
  user = aws_iam_user.platform_docker_user_pull.name
}

output "aws_ecr_url" {
  value = aws_ecr_repository.platform_infra_tester.repository_url
}
output "aws_iam_rw_accesskeyid" {
  value = aws_iam_access_key.platform_docker_user_push_key.id
}

output "aws_iam_rw_secretaccesskey" {
  sensitive = true
  value = aws_iam_access_key.platform_docker_user_push_key.secret
}
output "aws_iam_ro_accesskeyid" {
  value = aws_iam_access_key.platform_docker_user_pull_key.id
}

output "aws_iam_ro_secretaccesskey" {
  sensitive = true
  value = aws_iam_access_key.platform_docker_user_pull_key.secret
}
