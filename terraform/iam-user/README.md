# Oracle Cloud Infrastructure User Terraform Module

This [Terraform module](https://www.terraform.io/docs/modules/index.html) allows an [Oracle Cloud Infrastructure  user](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingusers.htm).

```hcl
module "iam_user1" {
  source           = "oracle-terraform-modules/iam/oci//modules/iam-user"
  tenancy_ocid     = "${var.tenancy_ocid}"
  user_name        = "tf_example_user1@oracle.com"
  user_description = "user1 created by terraform"
}
```

Note the following parameters:

Argument | Description
--- | ---
tenancy_ocid | (Required) Unique identifier (OCID) of the tenancy.
user_name | The name you assign to the user during creation. The name must be unique across all compartments in the tenancy.
user_description | (Required) Description of the user. The description is editable.

You can find the other parameters in [variables.tf](https://github.com/oracle-terraform-modules/terraform-oci-iam/blob/master/modules/iam-user/variables.tf).

Check out the [example](https://github.com/oracle-terraform-modules/terraform-oci-iam/tree/master/example) for fully-working sample code.
