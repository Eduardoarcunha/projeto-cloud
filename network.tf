# # 1. Creating VPC
# resource "aws_vpc" "rds_vpc" {
#   cidr_block = "10.0.0.0/16"

#   tags = {
#     Name = "rds_vpc"
#   }
# }

# # 2. Internet Gateway
# resource "aws_internet_gateway" "rds_igw" {
#   vpc_id = aws_vpc.rds_vpc.id

#   tags = {
#     Name = "rds_igw"
#   }
# }

# # 3. Public subnet
# resource "aws_subnet" "rds_subnet_public" {
#   vpc_id            = aws_vpc.rds_vpc.id
#   cidr_block        = "10.0.1.0/24"
#   availability_zone = data.aws_availability_zones.available.names[0]

#   tags = {
#     Name = "rds_subnet_public"
#   }
# }