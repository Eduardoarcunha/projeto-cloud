# Creating VPC
resource "aws_vpc" "rds_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "rds_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "rds_igw" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds_igw"
  }
}

# Public subnet
resource "aws_subnet" "rds_subnet_public" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "rds_subnet_public"
  }
}

# Private subnet
resource "aws_subnet" "rds_subnet_private" {
  count = 2
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = var.private_subnets_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "rds_subnet_private"
  }
}

# Public route table
resource "aws_route_table" "rds_route_public_table" {
  vpc_id = aws_vpc.rds_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rds_igw.id
  }

  tags = {
    Name = "rds_route_public_table"
  }
}

resource "aws_route_table_association" "rds_route_public_table_association" {
  subnet_id      = aws_subnet.rds_subnet_public.id
  route_table_id = aws_route_table.rds_route_public_table.id
}

# Private route table
resource "aws_route_table" "rds_route_private_table" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds_route_private_table"
  }
}

resource "aws_route_table_association" "rds_route_private_table_association" {
  subnet_id      = aws_subnet.rds_subnet_private[1].id
  route_table_id = aws_route_table.rds_route_private_table.id
}


# RDS subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [for subnet in aws_subnet.rds_subnet_private : subnet.id]
}