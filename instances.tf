# IAM role to access RDS
resource "aws_iam_role" "bastion_role" {
  name = "bastion_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
      tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "rds_profile" {
  name = "bastion"
  role = "${aws_iam_role.bastion_role.name}"
}

resource "aws_iam_role_policy_attachment" "dev-resources-ssm-policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 instance
resource "aws_instance" "ec2_instance" {
  ami           = "ami-0889a44b331db0194"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.rds_subnet_private[0].id
  vpc_security_group_ids = [aws_security_group.ec2_bastion_sg.id]
  iam_instance_profile = "${aws_iam_instance_profile.rds_profile.name}"

  tags = {
    Name = "ec2_instance"
  }
}