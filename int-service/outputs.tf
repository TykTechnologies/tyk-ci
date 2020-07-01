# Generated by: wf-gen from tyk-ci
# Generated at: Thu  2 Jul 00:58:55 IST 2020

data "terraform_remote_state" "integration" {
  backend = "remote"

  config = {
    organization = "Tyk"
    workspaces = {
      name = "dev-euc1"
    }
  }
}

output "int-service" {
  value = data.terraform_remote_state.integration.outputs.int-service
  description = "ECR creds for int-service repo"
}

output "region" {
  value = data.terraform_remote_state.integration.outputs.region
  description = "Region in which the env is running"
}
