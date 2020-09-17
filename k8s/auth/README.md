# auth
## introduction
This struct provides our authentication layer between internal tools and Github users.

In order to use it, you should generate your own 32 byte random string and override `cookie-secret`:
```
ruby -rsecurerandom -e 'puts SecureRandom.hex' | base64
```

You will also need to login to your bot's GitHub account and create a new oAuth2 application, granting it access to your organization and encoding the Client ID and Client Secret into base64 for the below kustomize file.

Now, kustomize as below, replacing the secrets and URLs as required:

```
---
apiVersion: v1
kind: Secret
metadata:
  labels:
    app: oauth2-proxy
    chart: oauth2-proxy-2.2.1
    heritage: Helm
    release: o2p
  name: o2p-oauth2-proxy
type: Opaque
data:
  cookie-secret: "<generated above>"
  client-secret: "<get from github and base64 encode>"
  client-id: "<get from github and base64 encode>"
---
  apiVersion: v1
  kind: ConfigMap
  metadata:
    labels:
      app: oauth2-proxy
      chart: oauth2-proxy-2.2.1
      heritage: Helm
      release: o2p
    name: o2p-oauth2-proxy
  data:
    oauth2-proxy.cfg: "email_domains = [ \"*\" ]\ngithub_org = \"11FSConsulting\"\nprovider = \"github\"\ncookie_domains = [ \".11fs-structs.com\" ]\ncookie_expire = \"1h0m0s\"\nwhitelist_domains = [\".11fs-structs.com\"]"
```

## upgrade
Note that `oauth2_proxy` has been renamed to `oauth2-proxy` including in configuration. To upgrade, you'll need to rename `oauth2_proxy.cfg` to `oauth2-proxy.cfg` and rename `cookie_domain` to `cookie_domains` and change it from a string to an array, even with 1 element as above example.
