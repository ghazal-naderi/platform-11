// Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.

variable "user_count" {
  default     = 0
}

variable "user_ids" {
  description = "List of user' ocids. "
  default     = []
}

variable "can_use_api_keys" {
  default     = "false"
}

variable "can_use_auth_tokens" {
  default     = "false"
}

variable "can_use_console_password" {
  default     = "false"
}

variable "can_use_customer_secret_keys" {
  default     = "false"
}

variable "can_use_smtp_credentials" {
  default     = "false"
}