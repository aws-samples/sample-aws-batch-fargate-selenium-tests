################################################################################
# Job Queue
################################################################################

output "job_queues_arn" {
  description = "Map of job queues arn created and their associated attributes"
  value       = module.batch.job_queues.default.arn
}

################################################################################
# Job Definitions
################################################################################

output "job_definitions_arn" {
  description = "Map of job definitions arn created and their associated attributes"
  value       = module.batch.job_definitions.batch.arn
}

output "job_definitions_name" {
  description = "Map of job definitions name created and their associated attributes"
  value       = module.batch.job_definitions.batch.name
}

output "eventbridge_bus_arn" {
  description = "The EventBridge Bus ARN"
  value       = module.eventbridge.eventbridge_bus_arn
}

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}
