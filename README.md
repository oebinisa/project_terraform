# Build AWS Infrastructure with Terraform

## 0. Introduction and Prerequisites

### 0a. Sample Project Architecture

The diagram below the infrastructure that will be created in this project

           │─────────│
           │ Route53 │
           └─────────
                │
           │─────────│
           │   ELB   │
           └─────────
                │
     │─────────────────────│
     │                     │
     │  │──────│ │──────│  │   │──────│
     │  │ EC2  │ │ EC2  │  │───│  S3  │
     │  └──────  └──────   │   └──────
     │                     │
     └─────────────────────
                │
           │─────────│
           │   RDS   │
           └─────────

### 0b. File Structure Tree

- The Directory layout below provides separation of implementation
- The aws-backend-state-locking section is optional but
  - needed in a collaborative environment
  - it ensures that sensitive data is encrypted (stored in s3)
  - aids automation
- The .modules section enables code reuse

       .
       ├── .modules
       │   ├── compute.tf
       │   ├── data_source.tf
       │   ├── database.tf
       │   ├── dnf.tf
       │   ├── install_website.sh
       │   ├── networking.tf
       │   ├── outputs.tf
       │   ├── storage.tf
       │   └── variables.tf
       │
       ├── dev
       │   ├── backend.tf
       │   └── main.tf
       │
       ├── production
       │   ├── backend.tf
       │   └── main.tf
       │
       └── staging
           ├── backend.tf
           └── main.tf

- The sections below will set up the DEV server environment as indicated in the File Tree Structure.
- The other server environments: staging, production, can be setup using the same process

### 0c. Terraform Setup

1.  Install Terraform:

        brew tap hashicorp/tap  // First install hashicorp tap
        brew install hashicorp/tap/terraform  // Install Terraform
        brew update  // update brew
        brew upgrade hashicorp/tap/terraform

2.  AWS CLI:

- Prerequisites:

  - IAM User with Programmatic Access
  - IAM Policy: AdministratorAccess
  - User Access Key ID, and Secret Access Key

- Install:

  - Download and install AWS CLI

- Configure:

  - Type "aws configure" in the Terminal
  - Paste Access Key ID and Secret Access Key when prompted
  - Enter region [us-east-1]

- Verify:
  - Access AWS S3 by typing "aws s3 ls" in the Terminal

3. Initialize Terraform in your Project base Directory

### 0d. Terraform Project Steps

- The project implementation workflow will follow the following steps:

1. Backend + Provider config for remote state locking (optional)
2. Compute Resources - EC2 instances
3. S3 Bucket
4. VPC
   - Subnet
5. Security Groups + Rules
6. ALB - Application Load Balancer
   - Listener
   - Listener Rule
   - ALB Target Group
   - Instances attachment to Target Group
   - Security Group + Rules for ALB
   - ALB
7. Route53 Zone + Record
8. RDS instance

## 1. Backend + Provider Config for State Locking (Optional)

1.  Create the following resources manually in order to store the terraform state in s3 and
    and lock it with DynmoDB:

- S3 Bucket: "ebi-devops-directive-tf-state"
- DynamoDB: "terraform-state-locking"

2.  Create base Project folder
3.  Inside the base project folder, create the folder to hold infrastructure for DEV. See
    File Structure Tree above.
4.  Create the dev/main.tf with the following contents.

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

5.  Create the dev/backend.tf with the following contents.

            terraform {
                backend "s3" {
                    bucket    = "ebi-tf-remote-state" # already created manually
                    key       = "terraform-module/project-name/terraform.tfstate" # terraform will create this in the bucket
                    region    = "us-east-1"
                    encrypt = true
                    # dynamodb_table = "terraform-state-lock" # optional. already created manually
                }
            }

6.  Inside the dev folder, run the terraform basic controls (init, plan, apply)

            terraform init
            terraform plan
            terraform apply

Respond to the prompt accordingly:

            Enter a value: yes

## 2. Create Compute Resources (EC2 Instances)

1.  Update the dev/main.tf with general parameters/variables for your project.
    These parameters would be referenced as we build the other sections of the project infrastructure.
    Updated content below:

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

2.  Inside the project base folder, create the folder to hold the different modules for the
    project infrastructure (.modules). See File Structure Tree above.

3.  Inside the .modules folder, create the following files:

4.  variables.tf
    The file will contain project wide variables

            # General Variables

            variable "region" {
                description = "Default region for provider"
                type        = string
                default     = "us-east-1"
            }

            variable "app_name" {
                description = "Name of the web application"
                type        = string
                default     = "website"
            }

            variable "environment_name" {
                description = "Deployment environment (dev/staging/production)"
                type        = string
                default     = "dev"
            }

            # EC2 Variables

            variable "instance_type" {
                description = "ec2 instance type"
                type        = string
                default     = "t2.micro"
            }

            variable "keypair" {
                description = "Keypair to be used"
                type        = string
                default     = "keypair0703"
            }

5.  data_source.tf

            # use data source to get the default vpc
            data "aws_vpc" "default_vpc" {
                default = true
            }

            # use data source to get the default subnet
            data "aws_subnet_ids" "default_subnet" {
                vpc_id = data.aws_vpc.default_vpc.id
            }

            # use data source to get a registered amazon linux 2 ami
            data "aws_ami" "amazon_linux_2" {
                most_recent = true
                owners      = ["amazon"]

                filter {
                    name   = "owner-alias"
                    values = ["amazon"]
                }

                filter {
                    name   = "name"
                    values = ["amzn2-ami-hvm*"]
                }
            }

            # use data source to get all avalablility zones in region
            data "aws_availability_zones" "available_zones" {}

6.  compute.tf
    It will create two EC2 instances.

            resource "aws_instance" "instance_1" {
                ami                    = data.aws_ami.amazon_linux_2.id
                instance_type          = var.instance_type
                subnet_id              = aws_default_subnet.default_az1.id
                vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
                key_name               = var.keypair
                user_data              = file("${path.module}/install_website.sh")

                tags = {
                    Name = "website server 1"
                }
            }

            resource "aws_instance" "instance_2" {
                ami                    = data.aws_ami.amazon_linux_2.id
                instance_type          = var.instance_type
                subnet_id              = aws_default_subnet.default_az2.id
                vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
                key_name               = var.keypair
                user_data              = file("${path.module}/install_website.sh")

                tags = {
                    Name = "website server 2"
                }
            }

7.  install_website.sh
    Create the script containing the user data to be executed to set up the ec2 instances

            #!/bin/bash
            sudo su
            yum update -y
            yum install -y httpd
            cd /var/www/html
            wget https://github.com/azeezsalu/techmax/archive/refs/heads/main.zip
            unzip main.zip
            cp -r techmax-main/* /var/www/html/
            rm -rf techmax-main main.zip
            systemctl enable httpd
            systemctl start httpd

## 3. Create S3 Bucket

1.  Update .modules/variables.tf with the following lines:

            # S3 Variables

            variable "bucket_prefix" {
                description = "prefix of s3 bucket for app data"
                type        = string
            }

2.  Create .modules/storage.tf

            # enter details of s3 bucket to be created
            resource "aws_s3_bucket" "bucket" {
                bucket_prefix = var.bucket_prefix
                force_destroy = true
            }

            # enable versioning on s3 bucket
            resource "aws_s3_bucket_versioning" "bucket_versioning" {
                bucket = aws_s3_bucket.bucket.id
                versioning_configuration {
                    status = "Enabled"
                }
            }

            # enable server-side encryption to s3 bucket
            resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto_conf" {
                bucket = aws_s3_bucket.bucket.bucket
                rule {
                    apply_server_side_encryption_by_default {
                        sse_algorithm = "AES256"
                    }
                }
            }

## 4. Create VPC and Subnet Infrastructure

1.  Create .modules/networking.tf

            # create default vpc if one does not exit
            resource "aws_default_vpc" "default_vpc" {
                tags    = {
                    Name  = "default vpc"
                }
            }

            # create default subnet (with 2 AZs) if one does not exit
            resource "aws_default_subnet" "default_az1" {
                availability_zone = data.aws_availability_zones.available_zones.names[0]

                tags   = {
                    Name = "default subnet"
                }
            }

            resource "aws_default_subnet" "default_az2" {
                availability_zone = data.aws_availability_zones.available_zones.names[1]

                tags   = {
                    Name = "default subnet"
                }
            }

## 5. Create Security Groups + Rules

1.  Update .modules/varables.tf with the following:

            variable "cidr_blocks" {
                description = "Public IP address of the server to ssh into. Gotten from console"
                type        = string
                default     = "129.205.113.172/32"
            }

2.  Update .modules/networking.tf

            # create security group for the ec2 instance
            resource "aws_security_group" "ec2_security_group" {
                name        = "ec2 security group"
                description = "allow access on ports 80 and 22"
                vpc_id      = aws_default_vpc.default_vpc.id

                ingress {
                    description      = "http access"
                    from_port        = 8080
                    to_port          = 8080
                    protocol         = "tcp"
                    cidr_blocks      = ["0.0.0.0/0"]
                }

                ingress {
                    description      = "ssh access"
                    from_port        = 22
                    to_port          = 22
                    protocol         = "tcp"
                    cidr_blocks      = [var.cidr_blocks]
                }

                egress {
                    from_port        = 0
                    to_port          = 0
                    protocol         = -1
                    cidr_blocks      = ["0.0.0.0/0"]
                }

                tags   = {
                    Name = "ec2 security group"
                }
            }

## 6. Create ALB - Application Load Balancer

1.  The following will be created:
    - Listener
    - Listener Rule
    - ALB Target Group
    - Instances attachment to Target Group
    - Security Group + Rules for ALB
    - ALB
2.  Update .modules/networking.tf

            # create the lb listener
            resource "aws_lb_listener" "http" {
                load_balancer_arn = aws_lb.load_balancer.arn

                port = 80

                protocol = "HTTP"

                # By default, return a simple 404 page
                default_action {
                    type = "fixed-response"

                    fixed_response {
                        content_type = "text/plain"
                        message_body = "404: page not found"
                        status_code  = 404
                    }
                }
            }

            # create the lb listener rule
            resource "aws_lb_listener_rule" "instances" {
                listener_arn = aws_lb_listener.http.arn
                priority     = 100

                condition {
                    path_pattern {
                        values = ["*"]
                    }
                }

                action {
                    type             = "forward"
                    target_group_arn = aws_lb_target_group.instances.arn
                }
            }

            # create the lb target group
            resource "aws_lb_target_group" "instances" {
                name     = "${var.app_name}-${var.environment_name}-tg"
                port     = 8080
                protocol = "HTTP"
                vpc_id   = data.aws_vpc.default_vpc.id

                health_check {
                    path                = "/"
                    protocol            = "HTTP"
                    matcher             = "200"
                    interval            = 15
                    timeout             = 3
                    healthy_threshold   = 2
                    unhealthy_threshold = 2
                }
            }

            # attach the instances to the lb target group
            resource "aws_lb_target_group_attachment" "instance_1" {
                target_group_arn = aws_lb_target_group.instances.arn
                target_id        = aws_instance.instance_1.id
                port             = 8080
            }

            resource "aws_lb_target_group_attachment" "instance_2" {
                target_group_arn = aws_lb_target_group.instances.arn
                target_id        = aws_instance.instance_2.id
                port             = 8080
            }

            # create security group for the application loadbalancer - alb
            resource "aws_security_group" "alb" {
                name = "${var.app_name}-${var.environment_name}-alb-security-group"
            }

            # create rules (inbound and outbound) for alb security group
            resource "aws_security_group_rule" "allow_alb_http_inbound" {
                type              = "ingress"
                security_group_id = aws_security_group.alb.id

                from_port   = 80
                to_port     = 80
                protocol    = "tcp"
                cidr_blocks = ["0.0.0.0/0"]

            }

            resource "aws_security_group_rule" "allow_alb_all_outbound" {
                type              = "egress"
                security_group_id = aws_security_group.alb.id

                from_port   = 0
                to_port     = 0
                protocol    = "-1"
                cidr_blocks = ["0.0.0.0/0"]

            }

            # create the alb
            resource "aws_lb" "load_balancer" {
            name               = "${var.app_name}-${var.environment_name}-app-lb"
            load_balancer_type = "application"
            subnets            = data.aws_subnet_ids.default_subnet.ids
            security_groups    = [aws_security_group.alb.id]

            }

## 7. Create Route53 Zone + Record

1.  Update .modules/varables.tf with the following:

            # Route 53 Variables

            variable "create_dns_zone" {
                description = "If true, create new route53 zone, if false read existing route53 zone"
                type        = bool
                default     = false
            }

            variable "domain" {
                description = "Domain for website"
                type        = string
            }

2.  Create .modules/dns.tf

            resource "aws_route53_zone" "primary" {
                count = var.create_dns_zone ? 1 : 0
                name  = var.domain
            }

            data "aws_route53_zone" "primary" {
                count = var.create_dns_zone ? 0 : 1
                name  = var.domain
            }

            locals {
                dns_zone_id = var.create_dns_zone ? aws_route53_zone.primary[0].zone_id : data.aws_route53_zone.primary[0].zone_id
                subdomain   = var.environment_name == "production" ? "" : "${var.environment_name}."
            }

            resource "aws_route53_record" "root" {
                zone_id = local.dns_zone_id
                name    = "${local.subdomain}${var.domain}"
                type    = "A"

                alias {
                    name                   = aws_lb.load_balancer.dns_name
                    zone_id                = aws_lb.load_balancer.zone_id
                    evaluate_target_health = true
                }
            }

## 8. Create RDS Instance

1.  Update .modules/varables.tf with the following:

            # RDS Variables

            variable "db_name" {
                description = "Name of DB"
                type        = string
            }

            variable "db_user" {
                description = "Username for DB"
                type        = string
            }

            variable "db_pass" {
                description = "Password for DB"
                type        = string
                sensitive   = true
            }

2.  Create .modules/database.tf

            # create the required rds layer
            resource "aws_db_instance" "db_instance" {
                allocated_storage   = 20
                storage_type        = "standard"
                engine              = "postgres"
                engine_version      = "12"
                instance_class      = "db.t2.micro"
                identifier          = var.db_name
                username            = var.db_user
                password            = var.db_pass
                skip_final_snapshot = true
            }

## 9. Execute and Verify Implementation

1.  If there are variables you'd like to output from the process, gather them in the outputs.tf file

2.  Create .modules/outputs.tf

            # print the ec2 instances and rds public ipv4 address
            output "instance_1_public_ipv4_address" {
                value = aws_instance.instance_1.public_ip
            }

            output "instance_2_public_ipv4_address" {
                value = aws_instance.instance_2.public_ip
            }

            output "db_instance_addr" {
                value = aws_db_instance.db_instance.address
            }

3.  Inside the dev folder, run the terraform basic controls (init, plan, apply)

            terraform init
            terraform plan
            terraform apply

Respond to the prompt accordingly:

            Enter a value: yes

2. Verify that all components are installed accordingly.

## 10. Destroy Infrastructure

1.  Remember to destroy infrasructure so as not to rack up bills
2.  Inside the dev folder, run the terraform basic controls (init, plan, apply)

            terraform destroy

Respond to the prompt accordingly:

            Enter a value: yes

## End.
