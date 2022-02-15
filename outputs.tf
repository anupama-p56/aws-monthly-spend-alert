output "budget_name" {
  value = aws_budgets_budget.monthly_budget.name
}

output "lambda_function" {
  value = aws_lambda_function.cost_alert.arn
}
