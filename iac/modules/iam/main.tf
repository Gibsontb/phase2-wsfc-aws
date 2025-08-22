# Author: tgibson
variable "project" { type = string }
variable "tags" { type = map(string) }

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["ec2.amazonaws.com"] }
  }
}

resource "aws_iam_role" "ssm_role" {
  name               = "${var.project}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.project}-instance-profile"
  role = aws_iam_role.ssm_role.name
  tags = var.tags
}

output "instance_profile_name" { value = aws_iam_instance_profile.this.name }
