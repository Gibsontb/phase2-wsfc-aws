# Author: tgibson
output "vpc_id" { value = module.vpc.vpc_id }
output "alb_dns_name" { value = module.alb.alb_dns_name }
output "asg_name" { value = module.asg.asg_name }
output "rds_endpoint" { value = module.rds.rds_endpoint }
output "s3_bucket" { value = module.s3.bucket_name }
output "logs_bucket" { value = module.s3.logs_bucket_name }
