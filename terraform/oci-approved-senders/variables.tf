variable "compartment_id" {
  description = "OCI compartment ID"
  type        = string
}

variable "senders" {
  description = "E-mail addresses to send from"
  type        = list(string)
  default     = []
}
