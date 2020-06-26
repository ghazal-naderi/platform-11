# Oracle Mailer module
This module creates a [Oracle mail sender] (https://www.oracle.com/uk/cloud/networking/email-delivery.html). This is useful to allow systems to send E-mails without expectation of reply.

## Usage
The module is simple to use. See the example: 

```
module "fusion_mailer" {
  source = "../../structs/oci-mailer"

  compartment_id       = "YOURCOMPARTMENT"
  sender_email_address = "dontspamme@lookmanohands.com
}
```

That will go ahead and create a sender. 