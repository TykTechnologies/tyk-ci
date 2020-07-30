output "cfssl_efs" {
  value       = aws_efs_file_system.cfssl.id
  description = "Shared with all environments"
}

output "config_efs" {
  value       = aws_efs_file_system.config.id
  description = "Shared with all environments"
}

output "region" {
  value       = data.aws_region.current.name
  description = "Region in which the dev env is running"
}

output "tyk" {
  value = map("key", aws_iam_access_key.integration["tyk"].id,
    "secret", aws_iam_access_key.integration["tyk"].secret,
  "ecr", aws_ecr_repository.integration["tyk"].repository_url)
  description = "gateway"
}

output "tyk-analytics" {
  value = map("key", aws_iam_access_key.integration["tyk-analytics"].id,
    "secret", aws_iam_access_key.integration["tyk-analytics"].secret,
  "ecr", aws_ecr_repository.integration["tyk-analytics"].repository_url)
  description = "dashboard"
}

output "tyk-pump" {
  value = map("key", aws_iam_access_key.integration["tyk-pump"].id,
    "secret", aws_iam_access_key.integration["tyk-pump"].secret,
  "ecr", aws_ecr_repository.integration["tyk-pump"].repository_url)
  description = "pump"
}

output "devshared" {
  value = map("key", aws_iam_access_key.devshared.id,
  "secret", aws_iam_access_key.devshared.secret)
  description = "shared developer key for access to all repos"
}

output "gromit_role_arn" {
  value       = aws_iam_role.gromit.arn
  description = "IAM role for gromit tasks"
}

output "registry_id" {
  value       = aws_ecr_repository.integration["tyk"].registry_id
  description = "IAM role for gromit tasks"
}
