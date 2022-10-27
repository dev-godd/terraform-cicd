## AUTOMATE INFRASTRUCTURE WITH IAC USING TERRAFORM PART 1

This manual implementation of this project using AWS console is at [Multi-site Project](https://github.com/chis0m/devops-pbl-projects/blob/master/p15-multiple-site-on-aws.md)

#### Initialize terraform
- in project folder create `main.tf` file
- add a provider
```terraform
provider "aws" {
  region  = var.region
  profile = "mycred" # aws credentials profile. If not specified, default will be used
}
```
- run `terraform init`

#### Install tflint
- `brew install tflint`
- in your project root create a `.tflint.hcl` and paste
```terraform
plugin "aws" {
    enabled = true
    version = "0.17.1"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```
- run `tflint --init`

#### using variables
- create `variables.tf` file and `terraform.tfvars`
- move your variables to variables.tf
- `terraform.tfvars` is like a .env file for terraform, where you set the actual values e,g
```terraform
# variable.tf file
variable "region" {
  type    = string
}

# terraform.tfvars file
region = "eu-central-1"
```


#### Terraform Workspaces
- create two workspaces, dev and prod with the command `terraform workspace new dev`
- List workspaces  `terraform workspace list`
- Show the exact workspace `terraform workspace show`
- Switch workspace `terraform workspace select prod`
