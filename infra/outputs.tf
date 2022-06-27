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
  value       = module.tf-mongodbatlas.mongodbatlas_project.ara.id
  description = "MongoDB Atlas project ID"
}

output "atlas_cluster_connection_strings" {
  value       = module.tf-mongodbatlas.mongodbatlas_cluster.ara.connection_strings
  description = "List of MongoDB Atlas cluster connection strings"
}

output "atlas_cluster_standard_conn_string" {
  value = module.tf-mongodbatlas.mongodbatlas_cluster.ara.connection_strings.0.standard
  description = "MongoDB Ara cluster connection string"
}

output "atlas_admin_username" {
  value       = module.tf-mongodbatlas.mongodbatlas_database_user.ara_admin.username
  description = "MongoDB Atlas cluster admin username"
}

output "atlas_admin_password" {
  value       = module.tf-mongodbatlas.mongodbatlas_database_user.ara_admin.password
  description = "MongoDB Atlas cluster admin password"
}