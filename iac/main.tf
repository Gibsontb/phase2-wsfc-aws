# Author: tgibson
module "vpc" {
  source              = "./modules/vpc"
  vpc_cidr            = var.vpc_cidr
  public_subnets      = var.public_subnets
  private_app_subnets = var.private_app_subnets
  private_db_subnets  = var.private_db_subnets
  tags                = var.tags
}

module "iam" {
  source  = "./modules/iam"
  project = var.project
  tags    = var.tags
}

module "security" {
  source            = "./modules/security"
  vpc_id            = module.vpc.vpc_id
  alb_allowed_cidrs = var.allowed_http_cidrs
  tags              = var.tags
}

module "s3" {
  source          = "./modules/s3"
  project         = var.project
  enable_alb_logs = var.enable_alb_logging
  tags            = var.tags
}

module "asg" {
  source               = "./modules/asg"
  vpc_id               = module.vpc.vpc_id
  private_subnets      = module.vpc.private_app_subnet_ids
  asg_min_size         = var.min_size
  asg_max_size         = var.max_size
  asg_desired          = var.desired_capacity
  instance_type        = var.instance_type
  app_sg_id            = module.security.app_sg_id
  iam_instance_profile = module.iam.instance_profile_name
  user_data            = file("./user_data/app.sh")
  tags                 = var.tags
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
  db_instance_class = var.db_instance_class
  db_name           = var.db_name
  db_username       = var.db_username
  tags              = var.tags
}
