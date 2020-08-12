output "mongo_host" {
  value       = aws_instance.mongo.private_ip
  description = "Shared with all environments"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC for infra"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "CIDR block of infra VPC"
}

output "r53_hosted_zoneid" {
  value = aws_route53_zone.dev_tyk_tech.zone_id
  description = "Zone ID for dev.tyk.technology"
}

output "tfstate_s3" {
  value = aws_s3_bucket.devenv.arn
  description = "S3 bucket used as devenv remote backend"
}

output "tfstate_lock_table" {
  value = aws_dynamodb_table.devenv_lock.id
  description = "Table for tfstate locks for devenv remote backend"
}
