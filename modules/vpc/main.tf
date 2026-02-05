module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = "${var.name}-VPC"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  # No public subnets or NAT - using VPC endpoints instead
  enable_nat_gateway = false

  # Enable DNS for VPC endpoints
  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags = var.vpc_subnet_tags
  vpc_tags            = var.vpc_tags
  tags                = var.tags
}

resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Security group for Batch Fargate tasks
resource "aws_security_group" "batch" {
  name        = "${var.name}-batch-sg"
  description = "Security group for Batch Fargate tasks"
  vpc_id      = module.vpc.vpc_id

  # HTTPS to VPC endpoints (ECR, ECS, CloudWatch Logs)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "HTTPS to VPC endpoints"
  }

  # S3 Gateway endpoint uses prefix list, not CIDR
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
    description     = "HTTPS to S3 Gateway endpoint"
  }

  # DNS resolution (required for VPC endpoint private DNS)
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "DNS resolution"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "DNS resolution TCP"
  }

  tags = merge(
    {
      Name = "BATCH"
    },
    var.tags
  )
}

# S3 Gateway Endpoint (free)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"

  route_table_ids = module.vpc.private_route_table_ids

  tags = merge(
    {
      Name = "${var.name}-s3-endpoint"
    },
    var.tags
  )
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "HTTPS to VPC"
  }

  tags = merge(
    {
      Name = "${var.name}-vpc-endpoints-sg"
    },
    var.tags
  )
}

# ECR API endpoint (for pulling container images)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-ecr-api-endpoint"
    },
    var.tags
  )
}

# ECR DKR endpoint (for Docker registry)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-ecr-dkr-endpoint"
    },
    var.tags
  )
}

# CloudWatch Logs endpoint (for container logging)
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-logs-endpoint"
    },
    var.tags
  )
}

# ECS endpoint (required for Fargate task scheduling)
resource "aws_vpc_endpoint" "ecs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-ecs-endpoint"
    },
    var.tags
  )
}

# ECS Agent endpoint (required for Fargate container agent communication)
resource "aws_vpc_endpoint" "ecs_agent" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecs-agent"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-ecs-agent-endpoint"
    },
    var.tags
  )
}

# ECS Telemetry endpoint (required for Fargate metrics)
resource "aws_vpc_endpoint" "ecs_telemetry" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecs-telemetry"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-ecs-telemetry-endpoint"
    },
    var.tags
  )
}

# VPC Flow Logs for network monitoring and security
resource "aws_flow_log" "this" {
  vpc_id                   = module.vpc.vpc_id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  iam_role_arn             = aws_iam_role.flow_logs.arn
  max_aggregation_interval = 60

  tags = merge(
    {
      Name = "${var.name}-flow-logs"
    },
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/${var.name}-vpc/flow-logs"
  retention_in_days = 14
  #tfsec:ignore:aws-cloudwatch-log-group-customer-key - Using AWS managed keys for demo purposes

  tags = var.tags
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.name}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  #tfsec:ignore:aws-iam-no-policy-wildcards - Wildcard required for VPC Flow Logs to write to log streams
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
      }
    ]
  })
}
