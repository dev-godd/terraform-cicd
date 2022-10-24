# This section will create the subnet group for the RDS  instance using the private subnet
resource "aws_db_subnet_group" "mc-rds" {
  name       = "acs-rds"
  subnet_ids = [aws_subnet.database-private[0].id, aws_subnet.database-private[1].id]

  tags = merge({ "Name" : "MC-RDS" }, local.tags)
}

# create the RDS instance with the subnets group
resource "aws_db_instance" "mc-rds" {
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"
  db_name           = var.db_name
  username          = var.master-username
  password          = var.master-password
  # tflint-ignore: aws_db_instance_default_parameter_group
  parameter_group_name   = "default.mysql5.7"
  db_subnet_group_name   = aws_db_subnet_group.mc-rds.name
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.datalayer-sg.id]
  multi_az               = "true"
}
