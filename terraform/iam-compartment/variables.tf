// Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.

variable "tenancy_ocid" {
  description = "The OCID of the tenancy. "
}

variable "compartment_name" {
  description = "The name you assign to the compartment during creation. The name must be unique across all compartments in the tenancy. "
}

variable "compartment_id" {
  description = "The OCID of the parent compartment containing the compartment. Allow for sub-compartments creation"
  default     = ""
}

variable "compartment_description" {
  description = "The description you assign to the compartment. Does not have to be unique, and it's changeable. "
  default     = ""
}

variable "enable_delete" {
  description = "Enable compartment delete on destroy. If true, compartment will be deleted when `terraform destroy` is executed; If false, compartment will not be deleted on `terraform destroy` execution"
  default     = true
}
