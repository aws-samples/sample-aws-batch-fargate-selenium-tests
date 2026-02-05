output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "image_uri" {
  description = "Full image URI with tag"
  value       = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
}
