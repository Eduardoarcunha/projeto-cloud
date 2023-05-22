# Public IP (Elastic IP)
output "public_ip" {
  value = aws_eip.rds_eip.public_ip
}

# Endpoint (Database endpoint)
output "endpoint" {
  value = aws_db_instance.rds_instance.address
}

# Port
output "port" {
  value = aws_db_instance.rds_instance.port
}