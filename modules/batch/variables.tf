variable "region" {
  type        = string
  description = "The region where the batch event is configured"
}

variable "name" {
  type        = string
  description = "The name used for the batch event"
}

variable "sg_ids" {
  description = "Batch Job security group IDs"
  type        = list(string)
}

variable "subnet_ids" {
  description = "Batch Job security group IDs"
  type        = list(string)
}

variable "job_image" {
  description = "The ECR registry where the image is located"
  type        = string
}

variable "job_vcpu" {
  description = "Amount of cpu to assign to a container. Possible values 0.25, 0.5, 1, 2, 4"
  type        = string
}

variable "job_mem" {
  description = "Amount of memory to assign to a container"
  type        = string
}

variable "tags" {
  description = "Mandatory tags for the resources"
  type        = map(string)
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "run_id" {
  description = "The name of job run ID used for the container overrides"
  type        = string
  default     = "default"
}
