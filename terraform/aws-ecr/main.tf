provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-2"
}

resource "aws_ecr_repository" "platform" {
  name                 = "platform"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "platform_policy" {
  repository = aws_ecr_repository.platform.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "Allow IAM access for ECR user",
            "Effect": "Allow",
            "Principal": { "AWS": "${aws_iam_user.platform_docker_user.arn}" },
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

resource "aws_iam_user_policy" "platform_ecr_rw" {
  name = "platform_ecr_rw"
  user = aws_iam_user.platform_docker_user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": [ "${aws_ecr_repository.platform.arn}" ]
    }
  ]
}
EOF
}

resource "aws_iam_user" "platform_docker_user" {
  name = "platform_docker_user"
  path = "/system/"
}

resource "aws_iam_access_key" "platform_docker_user_key" {
  user = aws_iam_user.platform_docker_user.name
}

output "aws_ecr_url" {
  value = aws_ecr_repository.platform.repository_url
}

output "aws_iam_accesskeyid" {
  value = aws_iam_access_key.platform_docker_user_key.id
}

output "aws_iam_secretaccesskey" {
  sensitive = true
  value = aws_iam_access_key.platform_docker_user_key.secret
}
