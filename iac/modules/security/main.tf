# Author: tgibson
variable "vpc_id" {}
variable "alb_allowed_cidrs" { type = list(string) }
variable "tags" { type = map(string) }

resource "aws_security_group" "alb" {
  name   = "sg-alb"
  vpc_id = var.vpc_id
  ingress { from_port=80  to_port=80  protocol="tcp" cidr_blocks=var.alb_allowed_cidrs }
  ingress { from_port=443 to_port=443 protocol="tcp" cidr_blocks=var.alb_allowed_cidrs }
  egress  { from_port=0   to_port=0   protocol="-1"  cidr_blocks=["0.0.0.0/0"] }
  tags = var.tags
}

resource "aws_security_group" "app" {
  name   = "sg-app"
  vpc_id = var.vpc_id
  ingress { from_port=80 to_port=80 protocol="tcp" security_groups=[aws_security_group.alb.id] }
  egress  { from_port=0  to_port=0  protocol="-1"  cidr_blocks=["0.0.0.0/0"] }
  tags = var.tags
}

resource "aws_security_group" "db" {
  name   = "sg-db"
  vpc_id = var.vpc_id
  ingress { from_port=5432 to_port=5432 protocol="tcp" security_groups=[aws_security_group.app.id] }
  egress  { from_port=0    to_port=0    protocol="-1"  cidr_blocks=["0.0.0.0/0"] }
  tags = var.tags
}

output "alb_sg_id" { value = aws_security_group.alb.id }
output "app_sg_id" { value = aws_security_group.app.id }
output "db_sg_id"  { value = aws_security_group.db.id }
