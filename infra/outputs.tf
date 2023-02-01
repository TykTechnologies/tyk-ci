output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC for infra"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "CIDR block of infra VPC"
}

output "zone-id" {
  value       = aws_route53_zone.dev_tyk_tech.zone_id
  description = "R53 zone id used by output "
}

output "tfstate_lock_table" {
  value = aws_dynamodb_table.devenv_lock.id
  description = "Table for tfstate locks for devenv remote backend"
}

output "cd" {
  sensitive = true
  value = tomap({
    "key" = aws_iam_access_key.deployment.id,
    "secret" = aws_iam_access_key.deployment.secret
  })
  description = "Service account for continuous deployment"
}

output "ci-atlas" {
  sensitive = true
  value = tomap({
    cstrings    = module.tf-mongodbatlas.atlas_cluster_ci_conn_strings
    user        = module.tf-mongodbatlas.atlas_admin_username
    password    = module.tf-mongodbatlas.atlas_admin_password
  })
  description = "MongoDB to store CI data"
}
