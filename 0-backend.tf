terraform {
  required_version = ">= 1.2.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
  backend "s3" {
    bucket  = "containar"
    key     = "terraformstate/terraform.tfstate"
    region  = "us-east-1"
    profile = "devops.chisom"
  }
}
