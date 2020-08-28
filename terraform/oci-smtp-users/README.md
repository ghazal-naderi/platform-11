# Manage smtp-only accounts in OCI

Required for sending email:
https://docs.cloud.oracle.com/en-us/iaas/Content/Email/Reference/gettingstarted.htm

- authentication credentials to connect to the oracle provides smtp services
- registered 'From:' addresses, these have to be tied to a compartment but must
  still be globally unique.
- configure 'smtp.email.me-jeddah-1.oci.oraclecloud.com' as smtp server.
