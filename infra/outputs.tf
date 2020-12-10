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

output "tfstate_lock_table" {
  value = aws_dynamodb_table.devenv_lock.id
  description = "Table for tfstate locks for devenv remote backend"
}

output "cd" {
  value = map(
    "key", aws_iam_access_key.deployment.id,
    "secret", aws_iam_access_key.deployment.secret
    )
  description = "Service account for continuous deployment"
}
