#####
# Web Application Firewall configuration
#####
module "waf" {
  source = "../.."

  name_prefix = "test-waf-setup"

  allow_default_action = true
  create_alb_association = false

  visibility_config = {
    cloudwatch_metrics_enabled = false
    metric_name                = "test-waf-setup-waf-main-metrics"
    sampled_requests_enabled   = false
  }

  rules = [
    {
      # Uses optional excluded_rules to exclude certain managed rules
      name     = "AWSManagedRulesCommonRuleSet-rule-1"
      priority = "1"

      override_action = "none"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "AWSManagedRulesCommonRuleSet-metric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        excluded_rule = [
#          "CrossSiteScripting_BODY",
#          "CrossSiteScripting_COOKIE",
#          "CrossSiteScripting_QUERYARGUMENTS",
#          "CrossSiteScripting_URIPATH",
#          "EC2MetaDataSSRF_BODY",
#          "EC2MetaDataSSRF_COOKIE",
#          "EC2MetaDataSSRF_QUERYARGUMENTS",
#          "EC2MetaDataSSRF_URIPATH",
#          "GenericLFI_BODY",
#          "GenericLFI_QUERYARGUMENTS",
#          "GenericLFI_URIPATH",
          "GenericRFI_BODY", #561 Authentication Error tekton
          "GenericRFI_QUERYARGUMENTS", #403 Forbidden dex and tekton
          "GenericRFI_URIPATH",
          "NoUserAgent_HEADER",
          "RestrictedExtensions_QUERYARGUMENTS",
          "RestrictedExtensions_URIPATH",
          "SizeRestrictions_BODY",
          "SizeRestrictions_Cookie_HEADER",
          "SizeRestrictions_QUERYSTRING",
          "SizeRestrictions_URIPATH",
          "UserAgent_BadBots_HEADER"
        ]
      }
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet-rule-2"
      priority = "2"

      override_action = "count"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "AWSManagedRulesKnownBadInputsRuleSet-metric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    },
    {
      # Uses an optional scope down statement to further refine what the rule is being applied to
      name     = "AWSManagedRulesAmazonIpReputationList-rule-3"
      priority = "3"

      override_action = "count"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "AWSManagedRulesAmazonIpReputationList-metric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    },
    {
      name     = "AWSManagedRulesBotControlRuleSet-rule-4"
      priority = "4"

      override_action = "count"

      visibility_config = {
        cloudwatch_metrics_enabled = false
        metric_name                = "AWSManagedRulesBotControlRuleSet-metric"
        sampled_requests_enabled   = false
      }

      managed_rule_group_statement = {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }
  ]

  tags = {
    "Environment" = "test"
  }
}
