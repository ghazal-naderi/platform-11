variable "tenancy_ocid" {}

variable "smtp_users" {
  description = "List of usernames for smtp-authentication"
  type        = list(string)
  default     = []
}
