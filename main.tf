provider "aws" {
  region = "us-east-1"
  shared_config_files      = ["C:/Users/eduar/.aws/config"]
  shared_credentials_files = ["C:/Users/eduar/.aws/credentials"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "private_subnets_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}

# 1. Creating VPC
resource "aws_vpc" "rds_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "rds_vpc"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "rds_igw" {
  vpc_id = aws_vpc.rds_vpc.id

  tags = {
    Name = "rds_igw"
  }
}

# 3. Public subnet
resource "aws_subnet" "rds_subnet_public" {
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "rds_subnet_public"
  }
}

# 4. Private subnet
resource "aws_subnet" "rds_subnet_private" {
  count = 2
  vpc_id            = aws_vpc.rds_vpc.id
  cidr_block        = var.private_subnets_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "rds_subnet_private"
  }
}

# 5. Public route table
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

# 6. Private route table
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

# 7. EC2 security group
resource "aws_security_group" "rds_ec2_sg" {
  name        = "rds_ec2_sg"
  description = "Allow traffic to EC2"

  vpc_id = aws_vpc.rds_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_ec2_sg"
  }
}

#8. RDS security group
resource "aws_security_group" "rds_db_sg" {
  name        = "rds_db_sg"
  description = "Allow traffic to RDS"

  vpc_id = aws_vpc.rds_vpc.id

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.rds_ec2_sg.id]
  }

  tags = {
    Name = "rds_db_sg"
  }
}

#9. RDS subnet group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [for subnet in aws_subnet.rds_subnet_private : subnet.id]
}

# 10. RDS instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  db_name              = "rds_db"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.id
  username             = "admin"
  password             = "admineduardo"
  vpc_security_group_ids = [aws_security_group.rds_db_sg.id]
  skip_final_snapshot = true

  tags = {
    Name = "rds_instance"
  }
}

# 11. Key pair
resource "aws_key_pair" "rds_ec2_key_pair" {
  key_name = "rds_kp"
  public_key = file("./key-pair/mykp.pub")
}

# 12. EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.rds_ec2_key_pair.key_name
  subnet_id     = aws_subnet.rds_subnet_public.id
  vpc_security_group_ids = [aws_security_group.rds_ec2_sg.id]

  user_data = <<-EOL
  #!/bin/bash
  sudo apt-get update -y && sudo apt install mysql-client -y
  EOL

  tags = {
    Name = "ec2_instance"
  }
}

# 13. Elastic IP
resource "aws_eip" "rds_eip" {
  vpc = true
  instance = aws_instance.ec2_instance.id

  tags = {
    Name = "rds_eip"
  }
}

# 14. Outputs
# Public IP (Elastic IP)
output "public_ip" {
  value = aws_eip.rds_eip.public_ip
}

# Endpoint (Database endpoint)
output "endpoint" {
  value = aws_db_instance.rds_instance.address
}

# Port
output "port" {
  value = aws_db_instance.rds_instance.port
}