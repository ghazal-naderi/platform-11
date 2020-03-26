resource "oci_identity_user_capabilities_management" "this" {
    #Required
    count    = length(var.user_ids)
    user_id  = var.user_ids[count.index]

    #Optional 
    can_use_api_keys             = var.can_use_api_keys
    can_use_auth_tokens          = var.can_use_auth_tokens
    can_use_console_password     = var.can_use_console_password
    can_use_customer_secret_keys = var.can_use_customer_secret_keys
    can_use_smtp_credentials     = var.can_use_smtp_credentials
}
