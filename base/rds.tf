locals {
  pg_port = 5432
}

module "rds_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "deptrack-db"
  description = "RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = local.pg_port
      to_port     = local.pg_port
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]
}

resource "random_password" "rds_master" {
  length = 16
  lower  = false
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "postgres15"

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine                = "postgres"
  engine_version        = "15"
  family                = "postgres15" # DB parameter group
  major_engine_version  = "15"         # DB option group
  instance_class        = "db.t4g.medium"
  allocated_storage     = 10
  max_allocated_storage = 50

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = "master"
  # The password is stored in the state
  password = random_password.rds_master.result
  port     = local.pg_port

  create_db_subnet_group = false
  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  # TODO: turn on deletion protection when stable
  deletion_protection = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "rds-monitoring"
  monitoring_role_use_name_prefix       = false
  monitoring_role_description           = "Role to ship enhanced monitoring to CloudWatch"

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
}

resource "aws_ssm_parameter" "rds_master" {
  name        = "/${local.name}/rds/master"
  type        = "SecureString"
  description = "Password for the RDS master user"
  value       = random_password.rds_master.result
}
