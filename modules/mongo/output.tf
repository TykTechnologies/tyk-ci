output "atlas_project_id" {
  value       = mongodbatlas_project.ara.id
  description = "MongoDB Atlas project ID"
}

output "atlas_cluster_id" {
  value       = mongodbatlas_cluster.ara.cluster_id
  description = "MongoDB Atlas cluster ID"
}

output "atlas_cluster_connection_strings" {
  value       = mongodbatlas_cluster.ara.connection_strings
  description = "List of MongoDB Atlas cluster connection strings"
}

output "atlas_admin_username" {
  value       = mongodbatlas_database_user.ara_admin.username
  description = "MongoDB Atlas cluster admin username"
}

output "atlas_admin_password" {
  value       = mongodbatlas_database_user.ara_admin.password
  description = "MongoDB Atlas cluster admin password"
}

# output "atlas_dashboard_username" {
#   value       = mongodbatlas_database_user.ara_dashboard.username
#   description = "MongoDB Atlas cluster Ara dashboard username"
# }

# output "atlas_dashboard_password" {
#   value       = mongodbatlas_database_user.ara_dashboard.password
#   description = "MongoDB Atlas cluster Ara dashboard password"
# }

# output "atlas_billing_username" {
#   value       = mongodbatlas_database_user.ara_billing.username
#   description = "MongoDB Atlas cluster Ara billing username"
# }

# output "atlas_billing_password" {
#   value       = mongodbatlas_database_user.ara_billing.password
#   description = "MongoDB Atlas cluster Ara billing password"
# }

output "atlas_cluster_ara_conn_string" {
  value = mongodbatlas_cluster.ara.connection_strings.0.standard
  description = "MongoDB Ara cluster connection string"
}

output "atlas_cidr" {
  value = var.atlas_cidr
  description = "MongoDB Atlas CIDR block to peer with ara vpc"
}

output "atlas_network_container_id" {
  value = mongodbatlas_network_container.ara.container_id
  description = "MongoDB Atlas network container ID"
}

output "atlas_network_peering_connection_id" {
  value = var.peering_enabled ? mongodbatlas_network_peering.ara.0.connection_id : null
  description = "MongoDB Atlas network peering connection ID"
}