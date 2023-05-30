output "atlas_project_id" {
  value       = mongodbatlas_project.ci.id
  description = "CI MongoDB Atlas project ID"
}

output "atlas_cluster_id" {
  value       = mongodbatlas_cluster.ci.cluster_id
  description = "CI MongoDB Atlas cluster ID"
}

output "atlas_cluster_connection_strings" {
  value       = mongodbatlas_cluster.ci.connection_strings
  description = "List of MongoDB Atlas cluster connection strings"
}

output "atlas_admin_username" {
  value       = mongodbatlas_database_user.ci_admin.username
  description = "CI MongoDB Atlas cluster admin username"
}

output "atlas_admin_password" {
  value       = mongodbatlas_database_user.ci_admin.password
  description = "CI MongoDB Atlas cluster admin password"
}

output "atlas_cluster_ci_conn_string" {
  value = mongodbatlas_cluster.ci.connection_strings.0.standard
  description = "CI MongoDB cluster connection string"
}

output "atlas_cidr" {
  value = var.atlas_cidr
  description = "MongoDB Atlas CIDR block to peer with ci vpc"
}

output "atlas_network_container_id" {
  value = mongodbatlas_network_container.ci.container_id
  description = "MongoDB Atlas network container ID"
}

output "atlas_network_peering_connection_id" {
  value = var.peering_enabled ? mongodbatlas_network_peering.ci.0.connection_id : null
  description = "MongoDB Atlas network peering connection ID"
}
