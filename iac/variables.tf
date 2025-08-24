# Author: tgibson
variable "project" {
  type    = string
  default = "phase2-web"
}
variable "env" {
  type    = string
  default = "dev"
}
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "public_subnets" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}
variable "private_app_subnets" {
  type    = list(string)
  default = ["10.0.10.0/24"]
} # can be 1 or 2+
variable "private_db_subnets" {
  type    = list(string)
  default = ["10.0.20.0/24"]
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "asg_min" {
  type    = number
  default = 2
}
variable "asg_max" {
  type    = number
  default = 4
}
variable "asg_desired" {
  type    = number
  default = 2
}
variable "app_port" {
  type    = number
  default = 80
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "rds_engine_version" {
  type    = string
  default = ""
} # latest
variable "rds_multi_az" {
  type    = bool
  default = false
}
variable "db_name" {
  type    = string
  default = "appdb"
}
variable "db_username" {
  type    = string
  default = "appuser"
}
variable "db_password" {
  type    = string
  default = "ChangeMe123!"
} # for exercise; use Secrets in prod

variable "allowed_http_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "enable_tls" {
  type    = bool
  default = false
}
variable "acm_certificate_arn" {
  type    = string
  default = ""
}
variable "enable_alb_logging" {
  type    = bool
  default = true
}

variable "tags" {
  type = map(string)
  default = {
  }

}
