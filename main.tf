terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "${var.region}"
  
  # Windows
  # shared_config_files      = ["C:/Users/eduar/.aws/config"]
  # shared_credentials_files = ["C:/Users/eduar/.aws/credentials"]
}