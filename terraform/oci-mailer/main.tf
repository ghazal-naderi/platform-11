resource "oci_email_sender" "mailer" {
  compartment_id = var.oci_compartment_id
  email_address  = var.send_address
}
