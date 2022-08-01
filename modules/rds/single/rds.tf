variable "vpc_id" {}
variable "app_cidr_blocks" {}
variable "db_subnet_groups" {}
variable "db_instance_type" {}
variable "db_name" {}
variable "db_user" {}
variable "db_pass" {}
variable "aws_region" {}
variable "stack" {}

module "mysql_sg" {
  source      = "../../internal-network/security_group"
  name        = "mysql_sg"
  vpc_id      = var.vpc_id
  port        = 3306
  cidr_blocks = ["0.0.0.0/0"]
}

# --------------------------------
# RDS DB SUBNET GROUP
# --------------------------------
resource "aws_db_subnet_group" "db-subnet-grp" {
  name        = "petclinic-db-sgrp"
  description = "Database Subnet Group"
  subnet_ids  = var.db_subnet_groups
}

# --------------------------------
# RDS (MYSQL)
# --------------------------------
resource "aws_db_instance" "db" {
  identifier              = "petclinic"
  allocated_storage       = 5
  engine                  = "mysql"
  engine_version          = "5.7"
  port                    = "3306"
  instance_class          = var.db_instance_type
  db_name                 = var.db_name
  username                = var.db_user
  password                = var.db_pass
  availability_zone       = "${var.aws_region}a"
  vpc_security_group_ids  = [module.mysql_sg.security_group_id]
  multi_az                = false
  db_subnet_group_name    = aws_db_subnet_group.db-subnet-grp.id
  parameter_group_name    = "default.mysql5.7"
  publicly_accessible     = true
  skip_final_snapshot     = true
  backup_retention_period = 0

  tags = {
    Name = "${var.stack}-db"
  }
}

output "aws_db_instance_address" {
  value = aws_db_instance.db.address
}
