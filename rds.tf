# RDS instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t2.micro"
  db_name              = "rds_db"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.id
  username             = "admin"
  password             = "adminrds"
  vpc_security_group_ids = [aws_security_group.instance_security_group.id]
  skip_final_snapshot = true

  tags = {
    Name = "rds_instance"
  }
}