# RDS PostgreSQL Database

# Generate random password for RDS master user if not provided
resource "random_password" "db_master" {
  count   = var.db_master_password == "" ? 1 : 0
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "deptrack" {
  name       = "${local.name_prefix}-db-subnet"
  subnet_ids = local.subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet"
  }
}

resource "aws_db_instance" "deptrack" {
  identifier     = "${local.name_prefix}-db"
  engine         = "postgres"
  engine_version = "16.11"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = local.dtrack_db_name
  username = "master"
  password = var.db_master_password != "" ? var.db_master_password : random_password.db_master[0].result

  db_subnet_group_name   = aws_db_subnet_group.deptrack.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name_prefix}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = false # Set to true for production
  multi_az           = false  # Set to true for production

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name = "${local.name_prefix}-db"
  }
}

# Store the master password in SSM for reference
resource "aws_ssm_parameter" "db_master_password" {
  name        = "/${local.name_prefix}/db_master_pass"
  description = "Master password for DependencyTrack RDS database"
  type        = "SecureString"
  value       = var.db_master_password != "" ? var.db_master_password : random_password.db_master[0].result
  key_id      = aws_kms_key.deptrack.id

  tags = {
    Name = "${local.name_prefix}-db-master-pass"
  }
}
