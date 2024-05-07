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
  low_cadence_repos  = ["tyk-pump", "tyk-sink", "tyk-identity-broker", "portal", "tyk-sync", "tyk-plugin-compiler", "tyk-automated-tests"]
  high_cadence_repos = ["tyk", "tyk-analytics"]

  pr_policy1 = jsondecode(file("files/pr_policy.json"))
  pr_policy2 = jsondecode(file("files/retain_all.json"))

  combined_policy = jsonencode({
    "rules" : concat(local.pr_policy1.rules, local.pr_policy2.rules)
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
  policy     = local.combined_policy
}

# Dependency Track filesystem
resource "aws_efs_file_system" "deptrack" {
  creation_token = "dependency track"
}

# Common filesystem for Tyk CD clusters
resource "aws_efs_file_system" "shared" {
  creation_token = "reproducible environments"
}

resource "aws_ssm_parameter" "cd_efs" {
  name        = "/cd/efs"
  type        = "String"
  description = "EFS ID for CD tasks"
  value       = aws_efs_file_system.shared.id
}

# CD secrets
resource "aws_kms_key" "cd" {
  description             = "usage delegated to tyk-ci/infra"
  deletion_window_in_days = 10
}

resource "aws_key_pair" "devacc" {
  key_name   = "devacc"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEy+rMTyKL3UaI6HKOBPbjLHu9AM9sxeZML1jfifjDoi alok@gauss"
}

resource "aws_s3_bucket" "assets" {
  bucket        = "assets.dev.tyk.technology"
  force_destroy = true
}

resource "aws_s3_object" "testreports" {
  key    = "testreports/"
  bucket = aws_s3_bucket.assets.id
  acl    = "private"
  source = "/dev/null"
}

