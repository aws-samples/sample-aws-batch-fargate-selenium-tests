module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.2.2"

  create_bus = false

  role_name = "${var.name}-batch-execution-role"

  rules = {
    event-batch = {
      name        = "${var.name}-target"
      description = "Capture Lambda Events for batch job execution"
      event_pattern = jsonencode({
        "detail" : {
          "runId" : [{
            "prefix" : "runId-"
          }]
        },
        "detail-type" : ["eventDrivenTest"],
        "source" : ["workflowDispatch"]
      })
      enabled = true
    }
  }

  targets = {
    event-batch = [
      {
        name            = "${var.name}-target"
        arn             = module.batch.job_queues.default.arn
        attach_role_arn = true
        batch_target = {
          job_definition = module.batch.job_definitions.batch.arn
          job_name       = module.batch.job_definitions.batch.name
        }
        input_transformer = local.order_input_transformer
      }
    ]
  }

  attach_policy_statements = true
  policy_statements = {
    batch = {
      effect = "Allow",
      actions = [
        "batch:SubmitJob",
        "events:Put*"
      ],
      resources = [
        module.batch.job_queues.default.arn,
        "${module.batch.job_queues.default.arn}:*"
      ]
    },
  }

  attach_policies    = true
  policies           = ["arn:aws:iam::aws:policy/service-role/AWSBatchServiceEventTargetRole"]
  number_of_policies = 1

  tags = var.tags

}

data "aws_iam_policy_document" "cloudwatch-logs-from-events" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.this.account_id}:log-group:/aws/${var.name}-events/*:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com", // unclear if this is necessary, but every example I could find has it
      ]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "cloudwatch-logs-from-events" {
  policy_document = data.aws_iam_policy_document.cloudwatch-logs-from-events.json
  policy_name     = "${var.name}-cloudwatch-logs-from-events"
}

resource "aws_cloudwatch_log_group" "eventbridge" {
  name              = "/aws/${var.name}-events/batch"
  retention_in_days = 14
  #tfsec:ignore:aws-cloudwatch-log-group-customer-key - Using AWS managed keys for demo purposes

  tags = var.tags
}
