// Opinionated VPC module: custom VPC, public/private subnets across AZs,
// IGW, NAT gateways, and basic routing. We keep this focused and reusable.

// Version and provider constraints are kept in the root module; this child
// module deliberately has no `terraform` or `provider` blocks.

locals {
  // Example: if data.aws_availability_zones.available.names returns
  // ["ap-south-1a", "ap-south-1b", "ap-south-1c"] and var.az_count = 2,
  // then local.azs = ["ap-south-1a", "ap-south-1b"].
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name = "${var.name}-vpc"
    },
    var.tags,
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.name}-igw"
    },
    var.tags,
  )
}

// Public subnets (one per AZ)
resource "aws_subnet" "public" {
  // Example: if local.azs = ["ap-south-1a", "ap-south-1b"],
  // this for_each map becomes:
  // { 0 = "ap-south-1a", 1 = "ap-south-1b" }
  for_each = { for idx, az in local.azs : idx => az }

  vpc_id = aws_vpc.this.id

  // Example: with vpc_cidr = "10.0.0.0/16", newbits = 4, and each.key = 0,
  // cidrsubnet("10.0.0.0/16", 4, 0) = "10.0.0.0/20"
  // each.key = 1 => "10.0.16.0/20", etc.
  cidr_block = cidrsubnet(var.vpc_cidr, 4, each.key)
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.name}-public-${each.value}"
      Tier = "public"
    },
    var.tags,
  )
}

// Private app subnets
resource "aws_subnet" "private_app" {
  // Same pattern as public subnets, but we offset the index by az_count
  // so private_app CIDR ranges do not overlap with public ranges.
  for_each = { for idx, az in local.azs : idx => az }

  vpc_id = aws_vpc.this.id

  // Example with vpc_cidr = "10.0.0.0/16", az_count = 2:
  // each.key = 0 => cidrsubnet("10.0.0.0/16", 4, 0 + 2) = "10.0.32.0/20"
  // each.key = 1 => "10.0.48.0/20"
  cidr_block = cidrsubnet(var.vpc_cidr, 4, each.key + var.az_count)
  availability_zone = each.value

  tags = merge(
    {
      Name = "${var.name}-private-app-${each.value}"
      Tier = "app"
    },
    var.tags,
  )
}

// Private DB subnets
resource "aws_subnet" "private_db" {
  // DB subnets use another offset so they sit in a separate IP range
  // from both public and app subnets.
  for_each = { for idx, az in local.azs : idx => az }

  vpc_id = aws_vpc.this.id

  // Example with vpc_cidr = "10.0.0.0/16", az_count = 2:
  // each.key = 0 => cidrsubnet("10.0.0.0/16", 4, 0 + 4) = "10.0.64.0/20"
  // each.key = 1 => "10.0.80.0/20"
  cidr_block = cidrsubnet(var.vpc_cidr, 4, each.key + var.az_count * 2)
  availability_zone = each.value

  tags = merge(
    {
      Name = "${var.name}-private-db-${each.value}"
      Tier = "db"
    },
    var.tags,
  )
}

// Public route table and associations
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name = "${var.name}-public-rt"
    },
    var.tags,
  )
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

// NAT gateways: one per AZ for high availability, each in a public subnet.
resource "aws_eip" "nat" {
  for_each = aws_subnet.public

  domain = "vpc"

  tags = merge(
    {
      Name = "${var.name}-nat-eip-${each.value.availability_zone}"
    },
    var.tags,
  )
}

resource "aws_nat_gateway" "this" {
  for_each = aws_subnet.public

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(
    {
      Name = "${var.name}-nat-${each.value.availability_zone}"
    },
    var.tags,
  )
}

// Private route tables for app subnets (each AZ -> its NAT)
resource "aws_route_table" "private_app" {
  for_each = aws_subnet.private_app

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }

  tags = merge(
    {
      Name = "${var.name}-private-app-rt-${each.value.availability_zone}"
    },
    var.tags,
  )
}

resource "aws_route_table_association" "private_app" {
  for_each       = aws_subnet.private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app[each.key].id
}

// Private route tables for DB subnets (no internet route – traffic stays internal)
resource "aws_route_table" "private_db" {
  for_each = aws_subnet.private_db

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.name}-private-db-rt-${each.value.availability_zone}"
    },
    var.tags,
  )
}

resource "aws_route_table_association" "private_db" {
  for_each       = aws_subnet.private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db[each.key].id
}

