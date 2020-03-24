// Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.

########################
# User
########################
resource "oci_identity_user" "this" {
  compartment_id = var.tenancy_ocid
  name           = var.user_name
  description    = var.user_description
}

data "oci_identity_users" "this" {
  compartment_id = var.tenancy_ocid

  filter {
    name   = "name"
    values = [var.user_name]
  }
}

locals {
  user_ids = "${concat(flatten(data.oci_identity_users.this.*.users), list(map("id", "")))}"
}
