provider "aws" {
  region = "us-east-1"

  # Linux
  shared_config_files      = ["$HOME/.aws/config"]
  shared_credentials_files = ["$HOME/.aws/credentials"]

  # Windows
  # shared_config_files      = ["%USERPROFILE%\.aws\config"]
  # shared_credentials_files = ["%USERPROFILE%\.aws\credentials"]
}

data "aws_availability_zones" "available" {
  state = "available"
}