resource "oci_identity_api_key" "this" {
  user_id   = var.user_id
  key_value = var.key_value
}