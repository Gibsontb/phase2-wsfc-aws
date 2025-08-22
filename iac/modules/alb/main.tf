# Author: tgibson
variable "vpc_id" {}
variable "public_subnets" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "asg_target_group_arn" { type = string }
variable "enable_tls" { type = bool }
variable "acm_certificate_arn" { type = string }
variable "alb_logs_bucket" { type = string }
variable "alb_allowed_cidrs" { type = list(string) }
variable "tags" { type = map(string) }

resource "aws_lb" "alb" {
  name               = "alb-web"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnets
  access_logs { bucket = var.alb_logs_bucket enabled = var.alb_logs_bucket != "" prefix = "alb-logs" }
  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_tls ? [1] : []
    content {
      type = "redirect"
      redirect { port="443" protocol="HTTPS" status_code="HTTP_301" }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_tls ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = var.asg_target_group_arn
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.enable_tls ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn
  default_action { type = "forward" target_group_arn = var.asg_target_group_arn }
}

output "alb_dns_name" { value = aws_lb.alb.dns_name }
