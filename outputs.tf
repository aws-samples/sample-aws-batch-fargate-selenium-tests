################################################################################
# ECR Repository
################################################################################

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_image_uri" {
  description = "Full image URI with tag"
  value       = module.ecr.image_uri
}

################################################################################
# Job Queue
################################################################################

output "job_queues_arn" {
  description = "Map of job queues arn created and their associated attributes"
  value       = module.batch_fargate.job_queues_arn
}

################################################################################
# Job Definitions
################################################################################

output "job_definitions_arn" {
  description = "Map of job defintions created and their associated attributes"
  value       = module.batch_fargate.job_definitions_arn
}

output "job_definitions_name" {
  description = "Map of job defintions created and their associated attributes"
  value       = module.batch_fargate.job_definitions_name
}

output "eventbridge_bus_arn" {
  description = "Map of job defintions created and their associated attributes"
  value       = module.batch_fargate.eventbridge_bus_arn
}


