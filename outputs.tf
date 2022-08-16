output "vpc_id" { value = aws_vpc.vpc.id }

output "vpc_cidr" { value = aws_vpc.vpc.cidr_block }

output "pub_subnet_ids" { value = aws_subnet.public-subnet.*.id }

output "lightsail_subnet_ids" { value = aws_subnet.lightsail-subnet.*.id }

output "lightsail_db_ids" { value = aws_subnet.db-subnet.*.id }

output "lightsail_instance_id" {
  value = aws_lightsail_instance.instance.*.id
}

output "db_id" { value = aws_db_instance.db.id }

output "db_password" { 
	value = data.aws_secretsmanager_secret_version.db-password.secret_string 
	sensitive = true
}
