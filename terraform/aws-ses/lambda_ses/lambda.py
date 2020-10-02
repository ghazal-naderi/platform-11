#!/usr/bin/python3.6
import urllib3
import json
import hashlib
http = urllib3.PoolManager()


def parse_delivery(message):
    emoji = "📧"
    delivery = message['delivery']
    smtp_response = delivery['smtpResponse']
    reporting_mta = delivery['reportingMTA']
    processing_time = delivery['processingTimeMillis']
    mta_ip = delivery['remoteMtaIp']
    timestamp = delivery['timestamp']
    return f"{emoji}\n*Time:* `{timestamp}`\n*From MTA:* `{reporting_mta}`\n*To MTA:* `{mta_ip}`\n*Response:* `{smtp_response}`\n*Processing Time:* `{processing_time}`ms"


def parse_bounce(message):
    emoji = "🛡️"
    bounce = message['bounce']
    bounce_type = bounce['bounceType']
    bounce_subtype = bounce['bounceSubType']
    timestamp = bounce['timestamp']
    feedback_id = bounce['feedbackId']
    try:
      mta_ip = bounce['remoteMtaIp']
    except NameError:
      mta_ip = "unknown"
    try:
      reporting_mta = bounce['reportingMTA']
    except NameError:
      reporting_mta = "unknown"
    try:
      del(bounce['bouncedRecipients'][0]['emailAddress'])
      diagnostics = json.dumps(bounce['bouncedRecipients'])
    except (NameError, KeyError, TypeError) as e:
      diagnostics = "No diagnostic information was available."
    return f"{emoji}\n*Time:* `{timestamp}`\n*From MTA:* `{reporting_mta}`\n*To MTA:* `{mta_ip}`\n*Type:* `{bounce_type}/{bounce_subtype}` bounce!\n`{diagnostics}`"


def parse_complaint(message):
    emoji = "⁉️"
    complaint = message['complaint']
    timestamp = complaint['timestamp']
    feedback_id = complaint['feedbackId']
    complaint_type = complaint['complaintSubType']
    return f"{emoji}\n*Time:* `{timestamp}`\n`{complaint_type}complaint`!\n*ID:* `{feedback_id}`"


def parse_unknown(message):
    emoji = "🦑"
    return f"{emoji}\nArgle-bargle glop-glyf."


def parse_notification(message):
    notification_type = message['notificationType']
    if notification_type == "Delivery":
        return parse_delivery(message)
    elif notification_type == "Bounce":
        return parse_bounce(message)
    elif notification_type == "Complaint":
        return parse_complaint(message)
    else:
        return parse_unknown(message)


def lambda_handler(event, context):
    url = "https://hooks.slack.com/services/xxx"
    message = json.loads(event['Records'][0]['Sns']['Message'])
    text = parse_notification(message)
    message_id = message['mail']['messageId']
    destination_domain = message['mail']['destination'][0].split("@")[1]
    destination_user = message['mail']['destination'][0].split("@")[0]
    destination_user_hash = hashlib.sha256(destination_user.encode('utf-8')).hexdigest()
    msg = {
        "channel": "#alerts-mail-dev",
        "username": "Email Alerts (Dev)",
        "text": f"*Message ID:* `{message_id}`\n*Destination:* _(sha256)_ `{destination_user_hash}@{destination_domain}`\n"+text,
        "icon_emoji": ""
    }

    encoded_msg = json.dumps(msg).encode('utf-8')
    resp = http.request('POST', url, body=encoded_msg)
    print({
        "message": event['Records'][0]['Sns']['Message'],
        "status_code": resp.status,
        "response": resp.data
    })

