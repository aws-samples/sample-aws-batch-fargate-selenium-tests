resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.name}-ecs-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_policy.json
}

data "aws_iam_policy_document" "ecs_task_execution_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "job_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "batch.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "job_execution_role" {
  name               = "${var.name}-job-exec"
  assume_role_policy = data.aws_iam_policy_document.job_execution_assume_role.json

  tags = var.tags
}

# Least privilege policy for batch job execution
data "aws_iam_policy_document" "job_execution_policy" {
  # S3 write access - restricted to test_reports path only
  #tfsec:ignore:aws-iam-no-policy-wildcards - Wildcard required for dynamic test report paths
  statement {
    sid    = "S3PutTestReports"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.this.arn}/test_reports/*"
    ]
  }

  # IAM PassRole - required for Batch
  statement {
    sid    = "PassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.job_execution_role.arn
    ]
  }
}

resource "aws_iam_role_policy" "job_execution_policy" {
  name   = "${var.name}-job-exec-policy"
  role   = aws_iam_role.job_execution_role.id
  policy = data.aws_iam_policy_document.job_execution_policy.json
}

resource "aws_iam_role_policy_attachment" "job_execution_attach" {
  role       = aws_iam_role.job_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}



###########################
# Lambda Event IAM Policy #
###########################

data "aws_iam_policy_document" "lambda_event_policy_document" {
  policy_id = "${var.name}-lambda-event-policy"

  # EventBridge permissions - scoped to default bus
  statement {
    sid    = "EventBridgePutEvents"
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = [
      "arn:aws:events:${var.region}:${data.aws_caller_identity.this.account_id}:event-bus/default"
    ]
  }

  # EventBridge rule management - scoped to specific rule pattern
  statement {
    sid    = "EventBridgeRuleManagement"
    effect = "Allow"
    actions = [
      "events:PutTargets",
      "events:DescribeRule",
      "events:ListRules"
    ]
    resources = [
      "arn:aws:events:${var.region}:${data.aws_caller_identity.this.account_id}:rule/${var.name}-*"
    ]
  }
}

resource "aws_iam_policy" "lambda_event_policy" {
  name        = "${var.name}-lambda-event-policy"
  description = "Policy for Lambda to publish events to EventBridge for AWS Batch job triggering"
  policy      = data.aws_iam_policy_document.lambda_event_policy_document.json

  tags = var.tags
}