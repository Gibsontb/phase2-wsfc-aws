# Author: tgibson
variable "project" { type = string default = "phase2-web" }
variable "env"     { type = string default = "dev" }
variable "region"  { type = string default = "us-east-1" }

variable "vpc_cidr"            { type = string      default = "10.0.0.0/16" }
variable "public_subnets"      { type = list(string) default = ["10.0.0.0/24","10.0.1.0/24"] }
variable "private_app_subnets" { type = list(string) default = ["10.0.10.0/24","10.0.11.0/24"] }
variable "private_db_subnets"  { type = list(string) default = ["10.0.20.0/24","10.0.21.0/24"] }

variable "instance_type"    { type = string default = "t3.micro" }
variable "min_size"         { type = number default = 2 }
variable "max_size"         { type = number default = 4 }
variable "desired_capacity" { type = number default = 2 }

variable "db_instance_class" { type = string default = "db.t3.micro" }
variable "db_name"           { type = string default = "appdb" }
variable "db_username"       { type = string default = "appuser" }

variable "enable_tls"          { type = bool   default = false }
variable "acm_certificate_arn" { type = string default = "" }

variable "enable_alb_logging" { type = bool default = true }

variable "allowed_http_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "phase2-web"
    Environment = "dev"
    Owner       = "tgibson"
    CostCenter  = "demo"
  }
}
