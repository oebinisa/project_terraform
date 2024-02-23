# store the terraform state file in s3
# and lock it with DynamoDB
terraform {
  backend "s3" {
    bucket    = "ebi-tf-remote-state" # create this manually or use Ansible
    key       = "terraform-module/project-name/terraform.tfstate" # terraform will create this in the bucket
    region    = "us-east-1"
    encrypt = true
    # dynamodb_table = "terraform-state-lock" # optional. create manually
  }
}