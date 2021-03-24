terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.31.0"
    }
  }
}

variable "environment" { }
data "aws_region" "current" {}
variable "account" { }
variable "domain" { }
variable "saml_provider_arn" { }

resource "aws_cloudwatch_log_group" "vpn" {
  name = "${var.environment == "prod" ? "" : join("",[var.environment,"-"])}VPN"
}

resource "aws_cloudwatch_log_stream" "vpn" {
  name           = "${var.environment == "prod" ? "" : join("",[var.environment,"-"])}VPN"
  log_group_name = aws_cloudwatch_log_group.vpn.name
}

resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "${var.environment == "prod" ? "" : join("",[var.environment,"-"])}vpn"
  server_certificate_arn = aws_acm_certificate.cert.arn
  client_cidr_block      = "10.254.0.0/16"
  dns_servers            = [cidrhost(data.aws_vpc.vpc.cidr_block, 2)]
  split_tunnel           = "true" # don't take over the default route

  authentication_options {
    type                       = "federated-authentication"
    saml_provider_arn          = var.saml_provider_arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = aws_cloudwatch_log_group.vpn.name
    cloudwatch_log_stream = aws_cloudwatch_log_stream.vpn.name
  }
  depends_on = [ aws_acm_certificate_validation.cert ]
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "vpn.${var.environment == "prod" ? "" : join("",[var.environment,"."])}${data.aws_region.current.name}.${var.account}.${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


data "aws_route53_zone" "env" {
  name         = "${var.environment == "prod" ? "" : join("",[var.environment,"."])}${data.aws_region.current.name}.${var.account}.${var.domain}"
  private_zone = false
}

resource "aws_route53_record" "vpn" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.env.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.vpn : record.fqdn]
}

data "aws_vpc" "vpc" {
  tags = {
    Name = "${var.environment == "prod" ? "" : join("",[var.environment,"."])}${data.aws_region.current.name}.${var.account}.${var.domain}"
  }
}

data "aws_subnet_ids" "vpc" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    SubnetType = "Utility"
  }
}

data "aws_subnet" "subnet" {
  for_each = data.aws_subnet_ids.vpc.ids
  id = each.value
}

resource "aws_ec2_client_vpn_network_association" "subnet" {
  for_each = data.aws_subnet_ids.vpc.ids
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = each.value
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = data.aws_vpc.vpc.cidr_block
  authorize_all_groups   = true
}
