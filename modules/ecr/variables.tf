variable "region" {
  description = "AWS region"
  type        = string
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag" {
  description = "Tag for the image to use"
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}
