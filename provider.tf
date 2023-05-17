provider "aws" {
  region = "us-east-1"
  shared_config_files      = ["C:/Users/eduar/.aws/config"]
  shared_credentials_files = ["C:/Users/eduar/.aws/credentials"]
}

data "aws_availability_zones" "available" {
  state = "available"
}