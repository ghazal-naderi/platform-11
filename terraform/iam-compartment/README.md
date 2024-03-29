# Oracle Cloud Infrastructure Compartment Terraform Module

This [Terraform module](https://www.terraform.io/docs/modules/index.html) allows an [Oracle Cloud Infrastructure  compartment](https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingcompartments.htm) to be used in either read-only mode or read/write mode.

```hcl
module "iam_compartment" {
  source                  = "oracle-terraform-modules/iam/oci//modules/iam-compartment"
  tenancy_ocid            = "${var.tenancy_ocid}"
  compartment_name        = "tf_example_compartment"
  compartment_description = "compartment created by terraform"
}
```

Note the following parameters:

Argument | Description
--- | ---
tenancy_ocid | (Required) Unique identifier (OCID) of the tenancy.
compartment_name | (Required) The name you assign to the compartment. The name must be unique across all compartments in a given tenancy.
compartment_description | (Required) Description of the compartment. You can edit the description.

You can find the other parameters in [variables.tf](https://github.com/oracle-terraform-modules/terraform-oci-iam/blob/master/modules/iam-compartment/variables.tf).

Check out the [example](https://github.com/oracle-terraform-modules/terraform-oci-iam/tree/master/example) for fully-working sample code.
