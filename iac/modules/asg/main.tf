# Author: tgibson
variable "vpc_id" {}
variable "private_subnets" { type = list(string) }
variable "asg_min_size" { type = number }
variable "asg_max_size" { type = number }
variable "asg_desired"  { type = number }
variable "instance_type" { type = string }
variable "app_sg_id" { type = string }
variable "iam_instance_profile" { type = string }
variable "user_data" { type = string }
variable "tags" { type = map(string) }

resource "aws_lb_target_group" "app" {
  name     = "tg-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check { path="/" port="80" healthy_threshold=2 unhealthy_threshold=2 timeout=5 interval=10 }
  tags = var.tags
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter { name="name" values=["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "lt-app-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  iam_instance_profile { name = var.iam_instance_profile }
  network_interfaces { security_groups=[var.app_sg_id] associate_public_ip_address=false }
  user_data = base64encode(var.user_data)
  tag_specifications { resource_type="instance" tags=var.tags }
  tags = var.tags
}

resource "aws_autoscaling_group" "asg" {
  name               = "asg-app"
  desired_capacity   = var.asg_desired
  max_size           = var.asg_max_size
  min_size           = var.asg_min_size
  vpc_zone_identifier= var.private_subnets

  launch_template { id = aws_launch_template.lt.id version = "$Latest" }
  target_group_arns = [aws_lb_target_group.app.arn]

  tag { key="Name" value="app-instance" propagate_at_launch=true }
}

output "asg_name" { value = aws_autoscaling_group.asg.name }
output "target_group_arn" { value = aws_lb_target_group.app.arn }
