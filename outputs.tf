# Usuario da Base de Dados
output "db_username" {
  value = aws_db_instance.rds_instance.username
}

# Endpoint da base de dados
output "rds_endpoint" {
  value = aws_db_instance.rds_instance.address
}

# ID da instância EC2
output "instance_id" {
  value = aws_instance.ec2_instance.id
}