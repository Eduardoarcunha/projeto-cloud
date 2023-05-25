# Create IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "EC2_SSM_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore policy to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2_role.name
}

# Create an instance profile for the EC2 instance and associate the IAM role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2_SSM_Instance_Profile"

  role = aws_iam_role.ec2_role.name
}


# Create EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ami.amazon_linux_2_ssm.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet[0].id
  vpc_security_group_ids = [
    aws_security_group.instance_security_group.id,
  ]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
}