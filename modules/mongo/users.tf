#### TBD

#ORG_INVITATION FOR MEMBERS --> Developer Team

# resource "mongodbatlas_org_invitation" "integration" {
#   username    = "Developer1@tyk.com"
#   org_id      = var.atlas_org_id
#   teams_ids   = [ "<TEAM-0-ID>", "<TEAM-1-ID>" ]
#   roles       = [ "ORG_MEMBER" ]
# }

#PROJECT_INVITATION FOR MEMBERS --> Developer Team

resource "mongodbatlas_project_invitation" "ci" {
  username    = "alok@tyk.io"
  project_id  = mongodbatlas_project.ci.id
  roles       = [ "GROUP_OWNER" ]
}

# --------------------------------------------------------------------

resource "mongodbatlas_database_user" "ci_admin" {
  project_id         = mongodbatlas_project.ci.id
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
