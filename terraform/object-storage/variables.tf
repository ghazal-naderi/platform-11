// Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.

variable "compartment_id" {}

variable "bucket_name" {}

variable "bucket_namespace" {}

// The description is only used if compartment_create = true.
variable "access_type" {
  default = "NoPublicAccess"
}
