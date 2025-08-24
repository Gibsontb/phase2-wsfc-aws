# Author: tgibson
module "vpc" {
  source = "./modules/vpc"

  # pass these in from root variables
  project = var.project
  env     = var.env

  # existing inputs
  vpc_cidr            = var.vpc_cidr
  public_subnets      = var.public_subnets
  private_app_subnets = var.private_app_subnets
  private_db_subnets  = var.private_db_subnets

  # optional extra tags (merged in module)
  tags = {
    Owner      = "TGibson"
    CostCenter = "Dev01"
  }
}

module "security" {
  source            = "./modules/security"
  vpc_id            = module.vpc.vpc_id
  alb_allowed_cidrs = var.allowed_http_cidrs
  app_port          = var.app_port
  tags              = var.tags
}

module "iam" {
  source  = "./modules/iam"
  project = var.project
  tags    = var.tags
}

module "asg" {
  source              = "./modules/asg"
  vpc_id              = module.vpc.vpc_id
  private_app_subnets = module.vpc.private_app_subnet_ids
  instance_type       = var.instance_type
  app_port            = var.app_port
  asg_min_size        = var.asg_min
  asg_max_size        = var.asg_max
  asg_desired         = var.asg_desired
  instance_profile    = module.iam.instance_profile
  app_sg_id           = module.security.app_sg_id
  tags                = var.tags
}

module "alb" {
  source               = "./modules/alb"
  vpc_id               = module.vpc.vpc_id
  public_subnets       = module.vpc.public_subnet_ids
  alb_sg_id            = module.security.alb_sg_id
  asg_target_group_arn = module.asg.target_group_arn
  enable_tls           = var.enable_tls
  acm_certificate_arn  = var.acm_certificate_arn
  alb_logs_bucket      = module.s3.logs_bucket_name
  alb_allowed_cidrs    = var.allowed_http_cidrs
  tags                 = var.tags
}

module "rds" {
  source            = "./modules/rds"
  vpc_id            = module.vpc.vpc_id
  db_subnet_ids     = module.vpc.private_db_subnet_ids
  db_sg_id          = module.security.db_sg_id
  db_instance_class = var.rds_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  engine_version    = var.rds_engine_version
  multi_az          = var.rds_multi_az
  tags              = var.tags
}

module "s3" {
  source  = "./modules/s3"
  project = var.project
  tags    = var.tags
}
