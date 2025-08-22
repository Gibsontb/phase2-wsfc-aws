# Author: tgibson
variable "vpc_id" {}
variable "db_subnet_ids" { type = list(string) }
variable "db_sg_id" { type = string }
variable "db_instance_class" { type = string }
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "engine_version" { type = string default = "" }
variable "tags" { type = map(string) }

resource "aws_db_subnet_group" "this" {
  name       = "db-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags       = var.tags
}

resource "random_password" "db" { length=20 special=true override_characters="_%@#-+=" }

resource "aws_secretsmanager_secret" "db" { name = "rds/${var.db_name}/credentials" tags = var.tags }

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({ username = var.db_username, password = random_password.db.result })
}

resource "aws_db_instance" "postgres" {
  identifier              = "postgres-app"
  engine                  = "postgres"
  engine_version          = var.engine_version != "" ? var.engine_version : null
  instance_class          = var.db_instance_class
  db_name                 = var.db_name
  username                = var.db_username
  password                = random_password.db.result
  allocated_storage       = 20
  skip_final_snapshot     = true
  vpc_security_group_ids  = [var.db_sg_id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  publicly_accessible     = false
  multi_az                = false
  storage_type            = "gp3"
  deletion_protection     = false
  tags = var.tags
}

output "rds_endpoint" { value = aws_db_instance.postgres.address }
