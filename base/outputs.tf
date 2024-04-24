output "shared_efs" {
  description = "EFS that is provided to CD tasks"
  value       = aws_efs_file_system.shared.id
}

output "deptrack_efs" {
  description = "EFS for Dependency Track"
  value       = aws_efs_file_system.deptrack.id
}

output "assets" {
  description = "ARN of S3 bucket containing logs, reports and other static assets"
  value       = aws_s3_bucket.assets.id
}

# Used by infra.tf
output "kms" {
  value = aws_kms_key.cd.arn
}

output "key_name" {
  value       = aws_key_pair.devacc.key_name
  description = "Key pair for EC2 instances. Private key in secrets.yaml."
}

output "vpc" {
  description = "A map of VPC information"
  value = {
    id              = module.vpc.vpc_id
    cidr            = module.vpc.vpc_cidr_block
    public_subnets  = module.vpc.public_subnets
    private_subnets = module.vpc.private_subnets
  }
}

output "rds" {
  description = "Shared PostgreSQL RDS instance"
  value = {
    address     = module.rds.db_instance_address
    port        = module.rds.db_instance_port
    mpasswd_arn = aws_ssm_parameter.rds_master.arn
  }
}

output "dns" {
  description = "R53 hosted zone details for dev.tyk.technology"
  value = {
    zone_id = aws_route53_zone.dev_tyk_tech.zone_id
    cert    = aws_acm_certificate.dev_tyk_tech.arn
  }
}
