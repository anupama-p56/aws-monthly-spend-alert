variable "region" {
  description = "AWS Region"
  default     = "eu-west-1"
}

variable "budget_amount" {
  description = "Monthly budget limit"
  type        = number
  default     = 100
}

variable "email_recipient" {
  description = "Email to send budget alerts"
  type        = string
}

variable "lambda_role_name" {
  description = "Name of the IAM role for Lambda"
  default     = "cost-alert-lambda-role"
}
