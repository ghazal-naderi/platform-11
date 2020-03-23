// Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.

output "compartment_id" {
  // This allows the compartment ID to be retrieved from the resource if it exists, and if not to use the data source.
  value = element(concat(oci_identity_compartment.this.*.id, list("")), 0)
}

output "compartment_name" {
  value = var.compartment_name
}
