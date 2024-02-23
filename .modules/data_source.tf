
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


