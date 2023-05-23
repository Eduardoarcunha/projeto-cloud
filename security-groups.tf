# EC2 security group
resource "aws_security_group" "ec2_bastion_sg" {
  name        = "ec2_bastion_sg"
  description = "Allow database access for bastion host"

  vpc_id = aws_vpc.rds_vpc.id
  

  # Inbound
  ingress {
    description = "MSSQL"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  # Outbound
  # HTTPS
  egress {
    description = "Outbound traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MSSQL
  egress {
    description = "Outbound traffic"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2_bastion_sg"
  }
}