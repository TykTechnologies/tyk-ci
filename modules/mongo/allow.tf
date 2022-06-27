resource "mongodbatlas_project_ip_access_list" "ara_custom" {
  project_id = mongodbatlas_project.ara.id
  comment    = "VPC network"

  for_each   = var.atlas_allowed_cidrs
  cidr_block = each.value
}

# TBFixed for some reason cant make provider version working from root template
# Added here temporary
terraform {
  required_providers {
    mongodbatlas = {
      version = "> 1.3.0"
      source = "mongodb/mongodbatlas"
    }    
  }
}