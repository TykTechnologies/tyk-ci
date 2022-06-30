resource "mongodbatlas_network_container" "ara" {
  atlas_cidr_block = var.atlas_cidr
  project_id       = mongodbatlas_project.ara.id
  provider_name    = "AWS"
  region_name      = var.atlas_region
}

// Create the peering connection request
resource "mongodbatlas_network_peering" "ara" {
  count = var.peering_enabled ? 1 : 0

  accepter_region_name   = var.peering_aws_region
  project_id             = mongodbatlas_project.ara.id
  container_id           = mongodbatlas_network_container.ara.id
  provider_name          = "AWS"
  route_table_cidr_block = var.peering_cidr
  vpc_id                 = var.peering_aws_vpc_id
  aws_account_id         = local.aws_account_id
}

# the following assumes an AWS provider is configured
# Accept the peering connection request
resource "aws_vpc_peering_connection_accepter" "peer" {
  count = var.peering_enabled ? 1 : 0

  vpc_peering_connection_id = mongodbatlas_network_peering.ara[count.index].connection_id
  auto_accept = true
}