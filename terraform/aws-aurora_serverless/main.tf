resource "aws_security_group" "db" {
  vpc_id      = var.vpc_id
  name        = format("%s-sg", var.name)
  description = format("Security Group for %s RDS instance", var.name)

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = var.ingress_cidr_blocks
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "db_subnets" {
  for_each          = var.db_subnet_confs
  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.name}-db-${each.value.az}-subnet"
  }
}

resource "aws_db_subnet_group" "default" {
  name        = var.name
  description = format("DB subnet group for %s RDS instance", var.name)
  subnet_ids  = [for s in aws_subnet.db_subnets : s.id]

  tags = {
    Name = var.name
  }
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier        = var.name
  engine                    = "aurora-postgresql"
  engine_mode               = "serverless"
  master_username           = var.master_username
  master_password           = random_password.temp.result
  backup_retention_period   = 7
  preferred_backup_window   = "02:00-03:00"
  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = format("%s-final-snapshot", var.name)
  vpc_security_group_ids    = [aws_security_group.db.id]
  db_subnet_group_name      = aws_db_subnet_group.default.name

  scaling_configuration {
    auto_pause               = var.auto_pause
    max_capacity             = var.max_capacity
    min_capacity             = var.min_capacity
    seconds_until_auto_pause = var.seconds_until_auto_pause
    timeout_action           = "ForceApplyCapacityChange"
  }

  lifecycle {
    ignore_changes = [master_password]
  }

  tags = {
    Name = var.name
  }
}

# This password should be immediately updated to avoid
# tf state containing sensitive data in plaintext.
resource "random_password" "temp" {
  length           = 16
  special          = true
  override_special = "_%@"
}
