# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "batch_security_group_id" {
  description = "Security group ID for Batch Fargate tasks"
  value       = aws_security_group.batch.id
}
