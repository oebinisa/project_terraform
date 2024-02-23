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
