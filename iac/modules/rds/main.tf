# Author: tgibson

variable "vpc_id" {}
variable "db_subnet_ids" { type = list(string) }
variable "db_sg_id"      { type = string }

variable "db_instance_class" { type = string }
variable "db_name"           { type = string }
variable "db_username"       { type = string }

variable "db_password" {
  type      = string
  sensitive = true
}

# Leave empty ("") to let AWS choose a valid default for the region
variable "engine_version" {
  type    = string
  default = ""
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "tags" { type = map(string) }

locals {
  # Convert empty string to null so Terraform doesn't send an invalid value
  engine_version_or_null = var.engine_version == "" ? null : var.engine_version
}

resource "aws_db_subnet_group" "this" {
  name       = "db-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "postgres" {
  identifier             = "pg-db"
  engine                 = "postgres"
  engine_version         = local.engine_version_or_null

  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  allocated_storage      = 20
  storage_type           = "gp3"

  vpc_security_group_ids = [var.db_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  publicly_accessible    = false
  multi_az               = var.multi_az

  skip_final_snapshot    = true
  deletion_protection    = false
  apply_immediately      = true

  tags = var.tags
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}
