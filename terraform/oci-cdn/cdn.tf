
resource "oci_waas_custom_protection_rule" "waas_custom_protection_rule" {
  compartment_id = var.compartment_ocid
  display_name   = "oci_waas_protection_rule"
  template       = "SecRule REQUEST_URI / \"phase:2,   t:none,   capture,   msg:'Custom (XSS) Attack. Matched Data: %%%{TX.0}   found within %%%{MATCHED_VAR_NAME}: %%%{MATCHED_VAR}',   id:{{id_1}},   ctl:ruleEngine={{mode}},   tag:'Custom',   severity:'2'\""
}
resource "oci_waas_waas_policy" "waas_policy" {
  #Required
  compartment_id = var.compartment_ocid
  domain         = var.primary_domain
  display_name   = var.waas_policy_display_name
  origins {
    #Required
    label = "primary"
    uri   = var.origin_uri
    http_port  = "80"
    https_port = "443"
  }
  policy_config {
    #Optional
    certificate_id                = var.website_certificateId
    cipher_group                  = "DEFAULT"
    client_address_header         = "X_FORWARDED_FOR"
    is_behind_cdn                 = true
    is_cache_control_respected    = true
    is_https_enabled              = true
    is_https_forced               = true
    is_origin_compression_enabled = true
    is_response_buffering_enabled = true
    is_sni_enabled                = true
    tls_protocols                 = ["TLS_V1_2","TLS_V1_3"]

    load_balancing_method {
      method                     = "ROUND_ROBIN"
      name                       = "ROUND_ROBIN"
      domain                     = var.origin_uri
      expiration_time_in_seconds = 10
    }
  }
  waf_config {
    #Optional
    access_rules {
      #Required
      action = "ALLOW"
      criteria {
        #Required
        condition = "URL_PART_CONTAINS"
        value     = var.regex_url
      }
      name = "waf_access_rule"
      bypass_challenges            = ["CAPTCHA","JS_CHALLENGE","HUMAN_INTERACTION_CHALLENGE"]
      redirect_url                 = var.primary_domain
      block_action                 = "SET_RESPONSE_CODE"
      block_error_page_code        = 403
      block_response_code          = 403
    }
      origin = "primary"

    address_rate_limiting {
      #Required
      is_enabled = true
      #Optional
      allowed_rate_per_address      = 10
      block_response_code           = 403
    }
    caching_rules {
      #Required
      action = "CACHE"
      caching_duration="PT1H"
      is_client_caching_enabled = true
      client_caching_duration= "PT24H"

      criteria {
        #Required
        condition = "URL_PART_CONTAINS"
        value = var.regex_url
      }
      name = "name"
    }
    device_fingerprint_challenge {
      #Required
      is_enabled = true
      challenge_settings {
        block_action = "SET_RESPONSE_CODE"
      }
    }
    custom_protection_rules {
      #Optional
      action = "DETECT"
      id     = oci_waas_custom_protection_rule.waas_custom_protection_rule.id
    }
    protection_settings {
      allowed_http_methods               = ["OPTIONS", "HEAD", "GET", "POST","PUT", "PATCH", "DELETE", "OPTIONS", "TRACE"]
      block_action                       = "SET_RESPONSE_CODE"
      block_error_page_code              = 403
      block_response_code                = 403
      is_response_inspected              = false
      media_types                        = [
        "text/html",
        "text/plain",
        "text/css",
        "application/json",
        "text/javascript"
      ]
      recommendations_period_in_days     = 10
    }
  }
}
resource "oci_waas_protection_rule" "waas_protection_rule" {
  waas_policy_id = oci_waas_waas_policy.waas_policy.id
  key            = "933161"
  action         = "DETECT"
}
resource "oci_dns_rrset" "waas_dns_rrset" {
  #Required
  domain = var.primary_domain
  rtype = "CNAME"
  zone_name_or_id = var.dns_zone
  compartment_id = var.compartment_ocid
  items {
    #Required
    domain = var.primary_domain
    rdata = var.waas_cname
    rtype = "CNAME"
    ttl = 300
  }
}