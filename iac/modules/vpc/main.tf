# Author: tgibson

# --- inputs ---
variable "project" { type = string }
variable "env"     { type = string }

variable "vpc_cidr" {}
variable "public_subnets" {
  type = list(string)
}
variable "private_app_subnets" {
  type = list(string)
}
variable "private_db_subnets" {
  type = list(string)
}
variable "tags" {
  type    = map(string)
  default = {}
}

# --- locals ---
locals {
  # Merge caller-supplied tags with required tags from variables.
  common_tags = merge(
    var.tags,
    {
      Project    = var.project
      Env        = var.env
      Owner      = lookup(var.tags, "Owner", "TGibson")
      CostCenter = lookup(var.tags, "CostCenter", "Dev01")
    }
  )

  # handy index->cidr maps
  public_map      = { for idx, cidr in var.public_subnets      : idx => cidr }
  private_app_map = { for idx, cidr in var.private_app_subnets : idx => cidr }
  private_db_map  = { for idx, cidr in var.private_db_subnets  : idx => cidr }
}

data "aws_availability_zones" "available" {}

# ---------------- VPC ----------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "vpc-${var.project}-${var.env}"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "igw-${var.project}-${var.env}" })
}

# ---------------- Public subnets ----------------
resource "aws_subnet" "public" {
  for_each                = local.public_map
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.available.names[tonumber(each.key)]
  map_public_ip_on_launch = true
  tags                    = merge(local.common_tags, { Name = "public-${each.value}" })
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "nat-eip-${var.project}-${var.env}" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  # pick the first public subnet deterministically
  subnet_id = element(values(aws_subnet.public)[*].id, 0)
  tags       = merge(local.common_tags, { Name = "nat-${var.project}-${var.env}" })
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "rt-public-${var.project}-${var.env}" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ---------------- Private app subnets ----------------
resource "aws_subnet" "private_app" {
  for_each          = local.private_app_map
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[tonumber(each.key)]
  tags              = merge(local.common_tags, { Name = "private-app-${each.value}" })
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "rt-private-app-${var.project}-${var.env}" })
}

resource "aws_route" "private_app_egress" {
  route_table_id         = aws_route_table.private_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_app_assoc" {
  for_each       = aws_subnet.private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app.id
}

# ---------------- Private DB subnets ----------------
resource "aws_subnet" "private_db" {
  for_each          = local.private_db_map
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[tonumber(each.key)]
  tags              = merge(local.common_tags, { Name = "private-db-${each.value}" })
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "rt-private-db-${var.project}-${var.env}" })
}

# Usually DB subnets have NO internet route; if you intended egress via NAT for DB, leave this,
# otherwise comment out the route below.
resource "aws_route" "private_db_egress" {
  route_table_id         = aws_route_table.private_db.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_db_assoc" {
  for_each       = aws_subnet.private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}

# --- outputs ---
output "vpc_id"                 { value = aws_vpc.this.id }
output "public_subnet_ids"      { value = [for s in aws_subnet.public      : s.id] }
output "private_app_subnet_ids" { value = [for s in aws_subnet.private_app : s.id] }
output "private_db_subnet_ids"  { value = [for s in aws_subnet.private_db  : s.id] }

