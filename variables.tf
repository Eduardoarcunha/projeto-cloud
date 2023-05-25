data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2_ssm" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

variable "region" {
  type        = string
  description = "Region for the resource deployment"
  default     = "us-east-1"
}

variable "private_subnets_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}

