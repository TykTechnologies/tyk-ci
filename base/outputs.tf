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
  })
  description = "gateway"
}

output "raava" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["raava"].id,
    secret = aws_iam_access_key.integration["raava"].secret,
  })
  description = "raava"
}

output "tyk-analytics" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["tyk-analytics"].id,
    secret = aws_iam_access_key.integration["tyk-analytics"].secret,
  })
  description = "dashboard"
}

output "tyk-pump" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["tyk-pump"].id,
    secret = aws_iam_access_key.integration["tyk-pump"].secret,
  })
  description = "pump"
}

output "tyk-identity-broker" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["tyk-identity-broker"].id,
    secret = aws_iam_access_key.integration["tyk-identity-broker"].secret,
  })
  description = "tib"
}

output "tyk-sink" {
  sensitive = true
  value = tomap({
    key = aws_iam_access_key.integration["tyk-sink"].id,
    secret = aws_iam_access_key.integration["tyk-sink"].secret,
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
