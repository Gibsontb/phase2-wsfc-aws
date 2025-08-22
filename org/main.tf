# Author: tgibson
locals { attach = var.apply_scps }

# Discover the Root ID if target_id is not provided
data "aws_organizations_roots" "roots" {
  count = local.attach && var.target_id == "" ? 1 : 0
}

locals {
  resolved_target_id = var.target_id != "" ? var.target_id : (
    local.attach && length(data.aws_organizations_roots.roots) > 0 ? data.aws_organizations_roots.roots[0].roots[0].id : ""
  )
}

# 1) Deny not-allowed regions
resource "aws_organizations_policy" "deny_not_allowed_regions" {
  count   = local.attach && var.enable_deny_not_allowed_regions ? 1 : 0
  name    = "DenyNotAllowedRegions"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Sid      = "DenyNotAllowedRegions"
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
      Condition = {
        StringNotEquals = { "aws:RequestedRegion" = var.allowed_regions }
      }
    }]
  })
}

resource "aws_organizations_policy_attachment" "deny_not_allowed_regions_attach" {
  count     = local.attach && var.enable_deny_not_allowed_regions ? 1 : 0
  policy_id = aws_organizations_policy.deny_not_allowed_regions[0].id
  target_id = local.resolved_target_id
}

# 2) Require tags on create
resource "aws_organizations_policy" "require_tags" {
  count   = local.attach && var.enable_require_tags ? 1 : 0
  name    = "RequireRequestTags"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version   = "2012-10-17",
    Statement = [for k in var.required_tag_keys : {
      Sid      = "DenyCreateWithoutTag${k}"
      Effect   = "Deny"
      Action   = [
        "ec2:RunInstances",
        "ec2:CreateVolume",
        "rds:CreateDBInstance",
        "s3:CreateBucket",
        "elasticloadbalancing:CreateLoadBalancer"
      ]
      Resource  = "*"
      Condition = {
        Null = { "aws:RequestTag/${k}" = "true" }
      }
    }]
  })
}

resource "aws_organizations_policy_attachment" "require_tags_attach" {
  count     = local.attach && var.enable_require_tags ? 1 : 0
  policy_id = aws_organizations_policy.require_tags[0].id
  target_id = local.resolved_target_id
}

# 3) Deny EC2 public IPs
resource "aws_organizations_policy" "deny_public_ip_instances" {
  count   = local.attach && var.enable_deny_public_ip_instances ? 1 : 0
  name    = "DenyInstancesWithPublicIP"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Sid      = "DenyAssociatePublicIp"
      Effect   = "Deny"
      Action   = [ "ec2:RunInstances" ]
      Resource = "*"
      Condition = {
        Bool = { "ec2:AssociatePublicIpAddress" = "true" }
      }
    }]
  })
}

resource "aws_organizations_policy_attachment" "deny_public_ip_instances_attach" {
  count     = local.attach && var.enable_deny_public_ip_instances ? 1 : 0
  policy_id = aws_organizations_policy.deny_public_ip_instances[0].id
  target_id = local.resolved_target_id
}

# 4) Deny open SSH/RDP
resource "aws_organizations_policy" "deny_open_ssh_rdp" {
  count   = local.attach && var.enable_deny_open_ssh_rdp ? 1 : 0
  name    = "DenyOpenSshRdp"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyOpen22"
        Effect   = "Deny"
        Action   = [ "ec2:AuthorizeSecurityGroupIngress" ]
        Resource = "*"
        Condition = {
          StringEquals = { "ec2:IpProtocol" = "tcp" }
          ForAnyValue:StringEquals = { "ec2:IpRanges" = "0.0.0.0/0" }
          NumericLessThanEquals = { "ec2:FromPort" = 22 }
          NumericGreaterThanEquals = { "ec2:ToPort" = 22 }
        }
      },
      {
        Sid      = "DenyOpen3389"
        Effect   = "Deny"
        Action   = [ "ec2:AuthorizeSecurityGroupIngress" ]
        Resource = "*"
        Condition = {
          StringEquals = { "ec2:IpProtocol" = "tcp" }
          ForAnyValue:StringEquals = { "ec2:IpRanges" = "0.0.0.0/0" }
          NumericLessThanEquals = { "ec2:FromPort" = 3389 }
          NumericGreaterThanEquals = { "ec2:ToPort" = 3389 }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "deny_open_ssh_rdp_attach" {
  count     = local.attach && var.enable_deny_open_ssh_rdp ? 1 : 0
  policy_id = aws_organizations_policy.deny_open_ssh_rdp[0].id
  target_id = local.resolved_target_id
}

# 5) Deny RDS publicly accessible
resource "aws_organizations_policy" "deny_rds_public" {
  count   = local.attach && var.enable_deny_rds_public ? 1 : 0
  name    = "DenyRdsPubliclyAccessible"
  type    = "SERVICE_CONTROL_POLICY"
  content = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Sid      = "DenyRdsPublic"
      Effect   = "Deny"
      Action   = [ "rds:CreateDBInstance", "rds:ModifyDBInstance" ]
      Resource = "*"
      Condition = {
        Bool = { "rds:PubliclyAccessible" = "true" }
      }
    }]
  })
}

resource "aws_organizations_policy_attachment" "deny_rds_public_attach" {
  count     = local.attach && var.enable_deny_rds_public ? 1 : 0
  policy_id = aws_organizations_policy.deny_rds_public[0].id
  target_id = local.resolved_target_id
}
