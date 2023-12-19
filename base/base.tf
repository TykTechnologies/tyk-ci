provider "aws" {
  region = "eu-central-1"
}

# Internal variables
locals {
  # name should match the tf workspace name
  name = "base-prod"
  # Repositories to create with per-repo access keys
  repos = ["tyk", "tyk-analytics", "tyk-pump", "tyk-sink", "tyk-identity-broker", "portal", "tyk-sync"]
  # An additional repo that will be linked to the tyk user from repos above
  tyk_repos = ["tyk-plugin-compiler"]
  # repo list based on release cadence
  low_cadence_repos = ["tyk-pump", "tyk-sink", "tyk-identity-broker", "portal", "tyk-sync", "tyk-plugin-compiler","tyk-automated-tests"]
  high_cadence_repos = ["tyk", "tyk-analytics"]

  pr_policy1 = jsondecode(file("files/pr_policy.json"))
  pr_policy2 = jsondecode(file("files/retain_all.json"))

  combined_policy = jsonencode({
    "rules": concat(local.pr_policy1.rules, local.pr_policy2.rules)
  })

  common_tags = {
    "managed" = "terraform",
    "ou"      = "syse",
    "purpose" = "ci",
    "env"     = local.name
  }

}

resource "aws_ecr_repository" "integration" {
  for_each = toset(concat(local.repos, local.tyk_repos))

  name                 = each.key
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "low_cadence" {
  
  for_each = toset(local.low_cadence_repos)

  depends_on = [aws_ecr_repository.integration]
  repository = each.key

  policy = file("files/pr_policy.json")

}

resource "aws_ecr_lifecycle_policy" "high_cadence" {
  for_each = toset(local.high_cadence_repos)

  depends_on = [aws_ecr_repository.integration]
  repository = each.key

  policy = local.combined_policy

}

# Common filesystem for all resources
resource "aws_efs_file_system" "shared" {
  creation_token = "reproducible environments"

  tags = local.common_tags
}

# CD secrets
resource "aws_kms_key" "cd" {
  description             = "usage delegated to tyk-ci/infra"
  deletion_window_in_days = 10
}

# terraform apply -target=null_resource.debug will show the rendered template
# resource "null_resource" "debug" {
#   triggers = {
#     json = "${data.template_file.tyk_repo_access.rendered}"
#   }
# }

