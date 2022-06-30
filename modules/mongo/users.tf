#### TBD

#ORG_INVITATION FOR MEMBERS --> Developer Team

# resource "mongodbatlas_org_invitation" "integration" {
#   username    = "Developer1@tyk.com"
#   org_id      = var.atlas_org_id
#   teams_ids   = [ "<TEAM-0-ID>", "<TEAM-1-ID>" ]
#   roles       = [ "ORG_MEMBER" ]
# }

#PROJECT_INVITATION FOR MEMBERS --> Developer Team

resource "mongodbatlas_project_invitation" "integration" {
  username    = "esteban@tyk.io"
  project_id  = mongodbatlas_project.ara.id
  roles       = [ "GROUP_OWNER" ]
}

# --------------------------------------------------------------------

resource "mongodbatlas_database_user" "ara_admin" {
  project_id         = mongodbatlas_project.ara.id
  username           = var.admin_username
  password           = var.admin_password
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }

  roles {
    role_name     = "dbAdminAnyDatabase"
    database_name = "admin"
  }
}

# resource "mongodbatlas_database_user" "ara_dashboard" {
#   project_id         = mongodbatlas_project.ara.id
#   username           = "ara_dashboard"
#   password           = random_password.mongodb_ara_dashboard.result
#   auth_database_name = "admin"

#   roles {
#     role_name     = "readWrite"
#     database_name = "ara_dashboard"
#   }
# }

# resource "mongodbatlas_database_user" "ara_billing" {
#   project_id         = mongodbatlas_project.ara.id
#   username           = "ara_billing"
#   password           = random_password.mongodb_ara_billing.result
#   auth_database_name = "admin"

#   roles {
#     role_name     = "readWrite"
#     database_name = "ara_billing"
#   }
# }
