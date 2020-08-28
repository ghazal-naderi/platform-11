# Oracle Mailer module
This module creates a [Oracle mail sender] (https://www.oracle.com/uk/cloud/networking/email-delivery.html). This is useful to allow systems to send E-mails without expectation of reply.

## Usage
The module is simple to use. See the example: 

```
module "oci-approved-servers" {
  source = "../../structs/oci-approved-servers"

  compartment_id = "YOURCOMPARTMENT"
  senders        = ["dontspamme@lookmanohands.com]
}
```

That will go ahead and create a sender. 
