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
  sensitive = true
  value = tomap({
    "key" = aws_iam_access_key.deployment.id,
    "secret" = aws_iam_access_key.deployment.secret
  })
  description = "Service account for continuous deployment"
}

# MongoAtlas Output
output "atlas_project_id" {
  value       = module.tf-mongodbatlas.atlas_project_id
  description = "MongoDB Atlas project ID"
}

output "atlas_cluster_connection_strings" {
  value       = module.tf-mongodbatlas.atlas_cluster_connection_strings
  description = "List of MongoDB Atlas cluster connection strings"
}

output "mongo_host" {
  value = module.tf-mongodbatlas.atlas_cluster_ara_conn_string
  description = "MongoDB Ara cluster connection string"
}

output "mongo_admin_username" {
  value       = module.tf-mongodbatlas.atlas_admin_username
  sensitive = true
  description = "MongoDB Atlas cluster admin username"
}

output "mongo_admin_password" {
  value       = module.tf-mongodbatlas.atlas_admin_password
  sensitive = true
  description = "MongoDB Atlas cluster admin password"
}