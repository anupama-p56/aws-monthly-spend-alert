import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
    budget_name = os.environ['BUDGET_NAME']
    email       = os.environ['EMAIL_RECIPIENT']
    region      = os.environ['REGION']

    # Clients
    budgets_client = boto3.client('budgets', region_name=region)
    ce_client      = boto3.client('ce', region_name=region)
    ses_client     = boto3.client('ses', region_name=region)

    # Get current month budget limit
    budget_response = budgets_client.describe_budget(
        AccountId=boto3.client('sts').get_caller_identity().get('Account'),
        BudgetName=budget_name
    )
    budget_limit = float(budget_response['Budget']['BudgetLimit']['Amount'])

    # Get actual usage using Cost Explorer
    today = datetime.utcnow().strftime('%Y-%m-%d')
    ce_response = ce_client.get_cost_and_usage(
        TimePeriod={'Start': f'{today[:8]}01', 'End': today},
        Granularity='MONTHLY',
        Metrics=['BlendedCost']
    )
    actual_usage = float(ce_response['ResultsByTime'][0]['Total']['BlendedCost']['Amount'])

    # Send email via SES
    subject = f"AWS Monthly Spend Report: ${actual_usage:.2f} / ${budget_limit}"
    body = f"Hello,\n\nYour AWS account has consumed ${actual_usage:.2f} of ${budget_limit:.2f} budget for this month."

    ses_client.send_email(
        Source=email,
        Destination={'ToAddresses':[email]},
        Message={
            'Subject': {'Data': subject},
            'Body': {'Text': {'Data': body}}
        }
    )

    return {"status": "success", "usage": actual_usage}
