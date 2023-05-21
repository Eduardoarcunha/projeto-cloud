# EC2 security group
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

# RDS security group
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