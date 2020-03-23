// Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.

########################
# Compartment
########################

resource "oci_identity_compartment" "this" {
  compartment_id = var.tenancy_ocid
  name           = var.compartment_name
  description    = var.compartment_description
}

data "oci_identity_compartments" "this" {
  compartment_id = var.tenancy_ocid

  filter {
    name   = "name"
    values = [var.compartment_name]
  }
}

locals {
  compartment_ids = "${concat(flatten(data.oci_identity_compartments.this.*.compartments), list(map("id", "")))}"
}
