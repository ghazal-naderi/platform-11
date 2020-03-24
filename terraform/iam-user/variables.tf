// Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.

variable "tenancy_ocid" {
  description = "The OCID of the tenancy. "
}

variable "user_name" {
  description = "The name you assign to the user during creation. The name must be unique across all compartments in the tenancy. "
}

variable "user_description" {
  description = "The description you assign to the user. Does not have to be unique, and it's changeable. "
  default     = ""
}
