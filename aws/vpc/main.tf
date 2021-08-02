#
# VPC Resources
#  * VPC
#  * Subnets (Public/Private)
#  * Internet Gateway
#  * Route Table
#

locals {
  eks_shared_map = var.eks_cluster_owned ? tomap({ "kubernetes.io/cluster/${var.eks_cluster_name}"="shared" }) : tomap({})
}

####################
# VPC
####################

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = merge(
    {
      "Name"=var.name
    },
    local.eks_shared_map
  )
}

####################
# Subnets
####################

resource "aws_subnet" "public_subnet" {
  count                   = length(var.public_subnet_cidr_blocks)
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.vpc.id

  tags = merge(
    {
      "Name"="${var.name}-public-subnet-${count.index}",
    },
    local.eks_shared_map
  )
}

resource "aws_subnet" "private_subnet" {
  count                   = length(var.private_subnet_cidr_blocks)
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = var.private_subnet_cidr_blocks[count.index]
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.vpc.id

  tags = merge(
    {
      "Name"="${var.name}-private-subnet-${count.index}",
    },
    local.eks_shared_map
  )
}

##########################################################
# Internet Gateway with Public Subnets Route Associations
##########################################################

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}-internet-gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}-public-route-table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id

  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table_association" "public_route_table_association" {
  count          = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
  route_table_id = aws_route_table.public_route_table.id
}

######################################################
# NAT Gateway with Private Subnets Route Associations
######################################################

# Elastic IP
resource "aws_eip" "vpc_eip" {
  count      = length(var.availability_zones)
  vpc        = true
  depends_on = [aws_internet_gateway.internet_gateway]

  tags = {
    Name = "${var.name}-nat-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = length(var.availability_zones)
  allocation_id = element(aws_eip.vpc_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)

  tags = {
    Name        = "${var.name}-nat-gateway-${count.index}"
  }

  depends_on = [aws_eip.vpc_eip, aws_internet_gateway.internet_gateway, aws_subnet.public_subnet]
}

resource "aws_route_table" "private_route_table" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.name}-private-route-table-${count.index}"
  }
}

resource "aws_route" "private_route" {
  count                   = length(var.availability_zones)
  route_table_id          = aws_route_table.private_route_table.*.id[count.index]
  destination_cidr_block  = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.nat_gateway.*.id[count.index]

  depends_on = [aws_internet_gateway.internet_gateway, aws_nat_gateway.nat_gateway]
}

resource "aws_route_table_association" "private_route_table_association" {
  count          = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private_subnet.*.id[count.index]
  route_table_id = aws_route_table.private_route_table.*.id[count.index]
}

####################
# VPC Endpoints
####################

# Allows private connections to AWS resources
resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
  count           = var.s3_region == null ? 0 : 1
  vpc_id          = aws_vpc.vpc.id
  service_name    = "com.amazonaws.${var.s3_region}.s3"
  route_table_ids = aws_route_table.private_route_table.*.id

  policy = <<POLICY
    {
      "Statement": [
          {
              "Action": "*",
              "Effect": "Allow",
              "Resource": "*",
              "Principal": "*",
              "Sid":""
          }
      ],
      "Version": "2008-10-17"
    }
  POLICY

  tags = {
    "Name" = "${var.name}-vpc-s3-endpoint"
  }
}