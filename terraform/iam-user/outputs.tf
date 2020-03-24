// Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.

output "user_id" {
  value = element(concat(oci_identity_user.this.*.id, list("")), 0)
}

output "user_name" {
  value = "${var.user_name}"
}
