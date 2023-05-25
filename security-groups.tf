# Create a security group for the EC2 instance
resource "aws_security_group" "instance_security_group" {
  name_prefix = "instance-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "security group for the EC2 instance"

  # Outbound rules (HTTP, MYSQL)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS outbound traffic"    
  }

  egress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow MYSQL outbound traffic"
  }

  # Inbound rules (MYSQL)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow MYSQL traffic from VPC"
  }

  tags = {
    Name = "EC2 Instance security group"
  }
}


# Security group for VPC Endpoints
resource "aws_security_group" "vpc_endpoint_security_group" {
  name_prefix = "vpc-endpoint-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "security group for VPC Endpoints"

  # Allow inbound HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
    description = "Allow HTTPS traffic from VPC"
  }

  tags = {
    Name = "VPC Endpoint security group"
  }
}

locals {
  endpoints = {
    "endpoint-ssm" = {
      name = "ssm"
    },
    "endpoint-ssmm-essages" = {
      name = "ssmmessages"
    },
    "endpoint-ec2-messages" = {
      name = "ec2messages"
    }
  }
}

resource "aws_vpc_endpoint" "endpoints" {
  vpc_id            = aws_vpc.vpc.id
  for_each          = local.endpoints
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.us-east-1.${each.value.name}"
  # Add a security group to the VPC endpoint
  security_group_ids = [aws_security_group.vpc_endpoint_security_group.id]
}