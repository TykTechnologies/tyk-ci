include(header.m4)
define(xTF_ENV, prod)dnl

data "terraform_remote_state" "integration" {
  backend = "remote"

  config = {
    organization = "Tyk"
    workspaces = {
      name = "base-xTF_ENV"
    }
  }
}

output "xREPO" {
  value = data.terraform_remote_state.integration.outputs.xREPO
  description = "ECR creds for xREPO repo"
}

output "region" {
  value = data.terraform_remote_state.integration.outputs.region
  description = "Region in which the env is running"
}
