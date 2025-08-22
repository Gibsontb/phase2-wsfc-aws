# Author: tgibson
variable "vpc_cidr" {}
variable "public_subnets" { type = list(string) }
variable "private_app_subnets" { type = list(string) }
variable "private_db_subnets" { type = list(string) }
variable "tags" { type = map(string) }

data "aws_availability_zones" "available" {}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.tags, { Name = "vpc-${var.tags.Project}-${var.tags.Environment}" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "igw-${var.tags.Project}-${var.tags.Environment}" })
}

resource "aws_subnet" "public" {
  for_each          = { for idx, cidr in var.public_subnets : idx => cidr }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[tonumber(each.key) % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "public-${each.key}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "rt-public" })
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

resource "aws_eip" "nat" { domain = "vpc" }

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(values(aws_subnet.public)[*].id, 0)
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_subnet" "private_app" {
  for_each          = { for idx, cidr in var.private_app_subnets : idx => cidr }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[tonumber(each.key) % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = false
  tags = merge(var.tags, { Name = "private-app-${each.key}" })
}

resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "rt-private-app" })
}

resource "aws_route" "private_app_nat" {
  route_table_id         = aws_route_table.private_app.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_app_assoc" {
  for_each       = aws_subnet.private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_subnet" "private_db" {
  for_each          = { for idx, cidr in var.private_db_subnets : idx => cidr }
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[tonumber(each.key) % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = false
  tags = merge(var.tags, { Name = "private-db-${each.key}" })
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "rt-private-db" })
}

resource "aws_route" "private_db_nat" {
  route_table_id         = aws_route_table.private_db.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_db_assoc" {
  for_each       = aws_subnet.private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}

output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "private_app_subnet_ids" { value = [for s in aws_subnet.private_app : s.id] }
output "private_db_subnet_ids" { value = [for s in aws_subnet.private_db : s.id] }
