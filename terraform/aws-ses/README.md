# aws-ses
This module creates an AWS SES, linking it to the provided `domain`. 

## Usage
- Copy `lambda_ses` directory into your own Terraform directory
- Edit `lambda_ses/lambda.py` and change the Slack webhook and channel to your own preference, this will become the destination for all alerts sent
- Bounces, Deliveries and Complaints will be published to 3 queues and Lambda will automatically send messages to Slack on each event. Bounces and Complaints will trigger an @channel message to be sent.

Use like:
```
module "ses" {
  source = "../structs/aws-ses"
  domain = "fakebank.com"
}
```

## Inputs
| Name | Default | Description |
| ---- | ------- | ----------- |
| `domain` | `fake.com` | The TLD from which to send emails |

You must have the directory `lambda_ses` containing `lambda.py` copied into your current working directory (in which you run `terraform apply`)
