variable "compartment_ocid" {}
variable "certificate_display_name" {
  default = "waas_website_certificate"
}
variable "waas_policy_display_name" {
  default = "waas_website_policy"
}
variable "website_certificateId" {
 }
variable "origin_uri" {
}
variable "regex_url" {
}
variable "primary_domain" {
}
variable "waas_cname" {}
variable "dns_zone" {}
variable "compartment" {}