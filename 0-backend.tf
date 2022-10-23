terraform {
  required_version = ">= 1.2.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket  = "containa"
    key     = "terraformstate/terraform.tfstate"
    region  = "us-east-1"
    profile = "entochmum"
  }
}
