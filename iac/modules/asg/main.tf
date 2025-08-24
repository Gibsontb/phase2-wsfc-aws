# Author: tgibson
variable "vpc_id" {}
variable "private_app_subnets" {
  type = list(string)
}
variable "instance_type" {
  type = string
}
variable "app_port" {
  type = number
}
variable "asg_min_size" {
  type = number
}
variable "asg_max_size" {
  type = number
}
variable "asg_desired" {
  type = number
}
variable "instance_profile" {
  type = string
}
variable "app_sg_id" {
  type = string
}
variable "tags" {
  type = map(string)
}

# ---- AMI ----
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ---- Launch Template ----
resource "aws_launch_template" "app" {
  # <= 6 chars required for name_prefix
  name_prefix   = "ltapp"
  image_id      = data.aws_ami.amzn2.id
  instance_type = var.instance_type

  iam_instance_profile { name = var.instance_profile }
  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(<<-BASH
    #!/bin/bash
    set -eux
    yum update -y
    amazon-linux-extras install nginx1 -y || yum install -y nginx || true
    cat >/usr/share/nginx/html/index.html <<'HTML'
    <!doctype html><html><head><title>OK</title></head><body><h1>It works</h1></body></html>
    HTML
    systemctl enable nginx
    systemctl start nginx
  BASH
  )

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }
}

# ---- Target Group ----
resource "aws_lb_target_group" "app" {
  # name_prefix must be <= 6 chars
  name_prefix = "tg"

  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# ---- Auto Scaling Group ----
resource "aws_autoscaling_group" "app" {
  name                = "asg"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired
  vpc_zone_identifier = var.private_app_subnets
  health_check_type   = "EC2"
  target_group_arns   = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---- Outputs ----
output "target_group_arn" { value = aws_lb_target_group.app.arn }
output "asg_name"         { value = aws_autoscaling_group.app.name }
