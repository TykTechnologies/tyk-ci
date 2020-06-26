# Generated by: wf-gen from tyk-ci
# Generated at: Thu  2 Jul 00:18:04 IST 2020

data "terraform_remote_state" "integration" {
  backend = "remote"

  config = {
    organization = "Tyk"
    workspaces = {
      name = "dev-euc1"
    }
  }
}

output "cfssl" {
  value = data.terraform_remote_state.integration.outputs.cfssl
  description = "ECR creds for cfssl repo"
}

output "region" {
  value = data.terraform_remote_state.integration.outputs.region
  description = "Region in which the env is running"
}
