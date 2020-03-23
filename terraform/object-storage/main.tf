// Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.

resource "oci_objectstorage_bucket" "test_bucket" {
  compartment_id = var.compartment_id
  name           = var.bucket_name
  namespace      = var.bucket_namespace
  access_type    = var.access_type
}