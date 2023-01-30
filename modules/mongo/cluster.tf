resource "mongodbatlas_project" "ara" {
  name   = var.cluster_name
  org_id = var.atlas_org_id

  dynamic "teams" {
    for_each = var.atlas_teams
    content {
      team_id    = teams.value.id
      role_names = teams.value.roles
    }
  }
}

resource "mongodbatlas_cluster" "ara" {
  name                   = var.cluster_name
  project_id             = mongodbatlas_project.ara.id
  mongo_db_major_version = "4.2"

  num_shards         = 1
  replication_factor = 3

  provider_name               = var.cluster_provider_name
  provider_instance_size_name = var.atlas_instance_size
  provider_region_name        = var.atlas_region
  provider_volume_type        = "STANDARD"
  provider_backup_enabled     = var.backup_enabled
  disk_size_gb                 = var.atlas_disk_size_gb
  auto_scaling_disk_gb_enabled = true

  # bi_connector = {
  #   "enabled"         = "false"
  #   "read_preference" = "secondary"
  # }

  advanced_configuration {
    minimum_enabled_tls_protocol = "TLS1_2"
    javascript_enabled           = true
    no_table_scan                = false
  }

  labels {
    key   = "project"
    value = var.cluster_name
  }

  dynamic "labels" {
    for_each = var.default_labels

    content {
      key   = labels.key
      value = labels.value
    }
  }

  depends_on = [mongodbatlas_network_container.ara]
}
