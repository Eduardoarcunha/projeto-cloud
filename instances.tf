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