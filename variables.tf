variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "enable_dns_support" {
  type    = bool
  default = "true"
}

variable "enable_dns_hostnames" {
  type    = bool
  default = "true"
}

variable "preferred_number_of_public_subnets" {
  type    = number
  default = 2
}
