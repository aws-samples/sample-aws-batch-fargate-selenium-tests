module "batch" {
  source  = "terraform-aws-modules/batch/aws"
  version = "3.0.3"

  instance_iam_role_name        = "${var.name}-batch-instance"
  instance_iam_role_description = "Task execution role for ${var.name}-batch"

  service_iam_role_name        = "${var.name}-batch-service"
  service_iam_role_description = "Service role ${var.name}-batch"

  compute_environments = {
    fargate = {
      name_prefix = "${var.name}-fargate"

      compute_resources = {
        type               = "FARGATE"
        max_vcpus          = 4
        security_group_ids = var.sg_ids
        subnets            = var.subnet_ids
      }
    }
  }

  job_queues = {
    default = {
      name     = "${var.name}-default-queue"
      state    = "ENABLED"
      priority = 1

      compute_environment_order = {
        fargate = {
          order                   = 1
          compute_environment_key = "fargate"
        }
      }

      create_scheduling_policy = false
    }
  }

  job_definitions = {
    batch = {
      name                  = "${var.name}-default-job"
      type                  = "container"
      propagate_tags        = true
      platform_capabilities = ["FARGATE"]

      container_properties = jsonencode({

        image = var.job_image

        runtimePlatform = {
          operatingSystemFamily = "LINUX",
          cpuArchitecture       = "X86_64"
        }

        fargatePlatformConfiguration = {
          platformVersion = "LATEST"
        },

        resourceRequirements = [
          {
            type  = "VCPU",
            value = var.job_vcpu,
          },
          {
            type  = "MEMORY",
            value = var.job_mem
          },
        ],

        executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
        jobRoleArn       = aws_iam_role.job_execution_role.arn

        environment = [
          {
            name  = "S3_BUCKET_NAME"
            value = var.bucket_name
          }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.batch.id
            awslogs-region        = var.region
            awslogs-stream-prefix = var.name
          }
        }
      })

      attempt_duration_seconds = 300
      retry_strategy = {
        attempts = 1
        evaluate_on_exit = {
          retry_error = {
            action       = "RETRY"
            on_exit_code = 1
          }
          exit_success = {
            action       = "EXIT"
            on_exit_code = 0
          }
        }
      }

      tags = {
        JobDefinition = "${var.name}-batch-job-definition"
      }
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "batch" {
  name              = "/aws/${var.name}-batch/jobs"
  retention_in_days = 14
  #tfsec:ignore:aws-cloudwatch-log-group-customer-key - Using AWS managed keys for demo purposes

  tags = var.tags
}
