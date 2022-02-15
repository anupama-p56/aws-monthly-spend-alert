# 1. Create Budget Notification
resource "aws_budgets_budget" "monthly_budget" {
  name         = "monthly-cost-limit"
  budget_type  = "COST"
  limit_amount = var.budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Notification
  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"

    subscriber_email_addresses = [var.email_recipient]
  }
}

# 2. Lambda Execution Role
resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

#3.  Attach required policies
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_budget" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/BudgetsReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_ses" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

# 4. Lambda Function
resource "aws_lambda_function" "cost_alert" {
  filename         = "lambda/python.zip"
  function_name    = "daily-cost-alert"
  role             = aws_iam_role.lambda_role.arn
  handler          = "python.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lambda/python.zip")
  environment {
    variables = {
      EMAIL_RECIPIENT = var.email_recipient
      BUDGET_NAME     = aws_budgets_budget.monthly_budget.name
      REGION          = var.region
    }
  }
}

# 5. EventBridge Rule (daily trigger)
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "daily-cost-alert-trigger"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "CostAlertLambda"
  arn       = aws_lambda_function.cost_alert.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_alert.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
}
