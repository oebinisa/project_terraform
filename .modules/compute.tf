# launch the ec2 instance and install website
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