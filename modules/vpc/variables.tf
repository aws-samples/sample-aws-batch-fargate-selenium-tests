/*---------------------------------------------------------
Provider Variable
---------------------------------------------------------*/
variable "region" {
  description = "The AWS Region e.g. us-east-1 for the environment"
  type        = string
}

/*---------------------------------------------------------
Common Variables
---------------------------------------------------------*/
variable "name" {
  description = "Project to be used on all the resources identification"
  type        = string
}

variable "tags" {
  description = "Mandatory tags for the resources"
  type        = map(string)
}

/*---------------------------------------------------------
VPC Variables
---------------------------------------------------------*/
variable "vpc_tags" {
  description = "Tags for the VPC"
  type        = map(string)
}

variable "vpc_subnet_tags" {
  description = "Tags for the private subnet"
  type        = map(string)
}
