# Creating VPC
resource "aws_vpc" "rds_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "rds_vpc"
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

# Private route table
resource "aws_route_table" "rds_route_private_table" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds_route_private_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.rds_subnet_private[0].id
  route_table_id = aws_route_table.rds_route_private_table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.rds_subnet_private[1].id
  route_table_id = aws_route_table.rds_route_private_table.id
}



# RDS subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [for subnet in aws_subnet.rds_subnet_private : subnet.id]
}