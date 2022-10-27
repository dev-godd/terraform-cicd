# Get list of availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  subnetCount = var.preferred_number_of_public_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_public_subnets
  tags = {
    Workspace       = terraform.workspace
    Environment     = "Dev"
    Owner-Email     = "devops.chisom@gmail.com"
    Managed-By      = "Terraform"
    Billing-Account = "1234567890"
  }
}

provider "aws" {
  region  = var.region
  profile = "devops.chisom"
}


# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags                 = merge({ "Name" = "MC-${terraform.workspace}-VPC" }, local.tags)
}
