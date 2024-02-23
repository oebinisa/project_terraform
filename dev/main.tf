terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# configured aws provider with proper credentials
provider "aws" {
  region = local.region
}

# define local variables
locals {
  environment_name = "dev"
  region = "us-east-1" 
}

variable "db_pass_1" {
  description = "password for database #1"
  type        = string
  sensitive   = true 
}

module "website" {
  source = "../.modules"

  # Input Variables
  bucket_prefix    = "website-data"
  environment_name = local.environment_name
  domain           = "devopsapp.com"
  app_name         = "website"
  instance_type    = "t2.micro"
  create_dns_zone  = true
  db_name          = "websitedb"
  db_user          = "foo"
  db_pass          = var.db_pass_1
}
