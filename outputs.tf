# Endpoint (Database endpoint)
output "endpoint" {
  value = aws_db_instance.rds_instance.address
}

# Private IP (EC2 instance private IP)
output "instance_id" {
  value = aws_instance.ec2_instance.id
}