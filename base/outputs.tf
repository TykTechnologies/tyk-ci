output "region" {
  value       = data.aws_region.current.name
  description = "Region for base, infra and devenvs"
}

output "cfssl_efs" {
  value       = aws_efs_file_system.cfssl.id
  description = "Shared with all environments"
}

output "config_efs" {
  value       = aws_efs_file_system.config.id
  description = "Shared with all environments"
}

output "tyk" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["tyk"].id,
    secret = aws_iam_access_key.integration["tyk"].secret,
    ecr = aws_ecr_repository.integration["tyk"].repository_url,
  })
  description = "gateway"
}

output "raava" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["raava"].id,
    secret = aws_iam_access_key.integration["raava"].secret,
    ecr = aws_ecr_repository.integration["raava"].repository_url,
  })
  description = "raava"
}

output "tyk-analytics" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["tyk-analytics"].id,
    secret = aws_iam_access_key.integration["tyk-analytics"].secret,
    ecr = aws_ecr_repository.integration["tyk-analytics"].repository_url,
  })
  description = "dashboard"
}

output "tyk-pump" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["tyk-pump"].id,
    secret = aws_iam_access_key.integration["tyk-pump"].secret,
    ecr = aws_ecr_repository.integration["tyk-pump"].repository_url,
  })
  description = "pump"
}

output "tyk-identity-broker" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["tyk-identity-broker"].id,
    secret = aws_iam_access_key.integration["tyk-identity-broker"].secret,
    ecr = aws_ecr_repository.integration["tyk-identity-broker"].repository_url,
  })
  description = "tib"
}

output "tyk-sink" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["tyk-sink"].id,
    secret = aws_iam_access_key.integration["tyk-sink"].secret,
    ecr = aws_ecr_repository.integration["tyk-sink"].repository_url,
  })
  description = "mdcb"
}

output "devshared" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.devshared.id,
    secret = aws_iam_access_key.devshared.secret
  })
  description = "shared developer key for access to all repos"
}
