resource "oci_identity_user" "this" {
  compartment_id = var.tenancy_ocid
  count          = length(var.smtp_users)
  name           = var.smtp_users[count.index]
  description    = "smtp-only user"
}

module "iam_capabilities_management" {
  source                       = "../../structs/iam-user-management"
  user_ids                     = oci_identity_user.this.*.id
  can_use_api_keys             = "false"
  can_use_auth_tokens          = "false"
  can_use_console_password     = "false"
  can_use_customer_secret_keys = "false"
  can_use_smtp_credentials     = "true"
}

resource "oci_identity_smtp_credential" "smtp" {
  count       = length(oci_identity_user.this.*.id)
  user_id     = oci_identity_user.this[count.index].id
  description = oci_identity_user.this[count.index].name
}
