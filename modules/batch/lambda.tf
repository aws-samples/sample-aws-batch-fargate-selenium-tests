module "aws_lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.21.1"

  function_name = "${var.name}-event-function"
  description   = "Pass event runId to EventBridge for batch job triggering"

  handler = "index.lambda_handler"
  runtime = "python3.12"
  publish = true

  # Performance and cost constraints
  timeout     = 30
  memory_size = 128

  # Observability - enable X-Ray tracing
  tracing_mode = "Active"

  # IAM configuration
  role_name     = "${var.name}-lambda-event-role"
  attach_policy = true
  policy        = aws_iam_policy.lambda_event_policy.arn

  # Enable CloudWatch Logs with encryption
  cloudwatch_logs_retention_in_days = 14

  # Environment variables
  environment_variables = {
    LOG_LEVEL      = "INFO"
    EVENT_BUS_NAME = "default"
  }

  source_path = "${path.module}/lambda-event/"

  tags = var.tags
}