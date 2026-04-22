data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = {
    for idx, az in local.azs : az => {
      index = idx
      az    = az
    }
  }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.az
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, each.value.index)
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-${each.value.az}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = {
    for idx, az in local.azs : az => {
      index = idx
      az    = az
    }
  }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.value.az
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, each.value.index + var.az_count)

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-${each.value.az}"
    Tier = "private"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  # Single NAT is a deliberate cost/resilience trade-off for pragmatic production:
  # lower cost with reduced AZ fault tolerance for outbound traffic.
  subnet_id = aws_subnet.public[local.azs[0]].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  for_each = aws_subnet.public

  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt-${each.key}"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[each.key].id
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-${each.key}"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_network_acl" "public" {
  for_each = aws_subnet.public

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-nacl-${each.key}"
    Tier = "public"
  })
}

resource "aws_network_acl_association" "public" {
  for_each = aws_subnet.public

  network_acl_id = aws_network_acl.public[each.key].id
  subnet_id      = each.value.id
}

resource "aws_network_acl_rule" "public_ingress_http" {
  for_each = aws_network_acl.public

  network_acl_id = each.value.id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 100
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_ingress_https" {
  for_each = aws_network_acl.public

  network_acl_id = each.value.id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_ingress_ephemeral_tcp" {
  for_each = aws_network_acl.public

  network_acl_id = each.value.id
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 120
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_ingress_ephemeral_udp" {
  for_each = aws_network_acl.public

  network_acl_id = each.value.id
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  rule_number    = 130
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_egress_all" {
  for_each = aws_network_acl.public

  network_acl_id = each.value.id
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 100
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-nacl-${each.key}"
    Tier = "private"
  })
}

resource "aws_network_acl_association" "private" {
  for_each = aws_subnet.private

  network_acl_id = aws_network_acl.private[each.key].id
  subnet_id      = each.value.id
}

resource "aws_network_acl_rule" "private_ingress_vpc_all" {
  for_each = aws_network_acl.private

  network_acl_id = each.value.id
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 100
  cidr_block     = var.vpc_cidr
}

resource "aws_network_acl_rule" "private_egress_all" {
  for_each = aws_network_acl.private

  network_acl_id = each.value.id
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 100
  cidr_block     = "0.0.0.0/0"
}

# With single NAT and route-table steering, private subnets still avoid direct
# internet ingress even with broad egress NACL rules.

resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt in aws_route_table.private : rt.id]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-s3-gateway-endpoint"
  })
}
