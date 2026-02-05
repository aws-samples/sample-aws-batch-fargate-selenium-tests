module "batch_vpc" {
  source = "./modules/vpc"

  name   = var.project
  region = var.region

  tags            = var.tags
  vpc_tags        = var.vpc_tags
  vpc_subnet_tags = var.vpc_subnet_tags
}

module "ecr" {
  source = "./modules/ecr"

  region          = var.region
  repository_name = "${var.project}-selenium"
  image_tag       = var.image_tag

  tags = var.tags
}

module "batch_fargate" {
  source = "./modules/batch"

  name   = var.project
  region = data.aws_region.current.name

  sg_ids     = [module.batch_vpc.batch_security_group_id]
  subnet_ids = module.batch_vpc.private_subnet_ids

  job_image   = module.ecr.image_uri
  job_vcpu    = var.job_definition_vcpu
  job_mem     = var.job_definition_memory
  bucket_name = "${var.project}-${var.bucket_name_suffix}"

  tags = var.tags

  depends_on = [module.batch_vpc]
}
