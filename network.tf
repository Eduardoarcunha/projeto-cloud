# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-${var.region}"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw-${var.region}"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name = "Public Subnet"
  }
}

# Create a private subnet
resource "aws_subnet" "private_subnet" {
  count = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnets_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "rds_subnet_private"
  }
}

# Create a NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "ngw-${var.region}"
  }
}

# Create an EIP for the NAT gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

# Create a public route table and associate it with the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Public route table"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a private route table and associate it with the private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "Private route table"
  }
  
}

resource "aws_route_table_association" "private_route_table_association" {
  count = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

#RDS subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [for subnet in aws_subnet.private_subnet : subnet.id]
}