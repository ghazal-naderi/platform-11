resource "oci_email_sender" "mailer" {
  compartment_id = var.compartment_id
  count          = length(var.senders)
  email_address  = var.senders[count.index]
}
