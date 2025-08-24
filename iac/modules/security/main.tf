# Author: tgibson
variable "vpc_id" {}
variable "alb_allowed_cidrs" {
  type = list(string)
}
variable "app_port" {
  type = number
}
variable "tags" {
  type = map(string)
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  vpc_id      = var.vpc_id
  description = "ALB security group"
  tags        = merge(var.tags, { Name = "sg-alb" })
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_allowed_cidrs
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app" {
  name        = "app-sg"
  vpc_id      = var.vpc_id
  description = "App instances"
  tags        = merge(var.tags, { Name = "sg-app" })
  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name        = "db-sg"
  vpc_id      = var.vpc_id
  description = "DB access from app only"
  tags        = merge(var.tags, { Name = "sg-db" })
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "alb_sg_id" { value = aws_security_group.alb.id }
output "app_sg_id" { value = aws_security_group.app.id }
output "db_sg_id" { value = aws_security_group.db.id }
