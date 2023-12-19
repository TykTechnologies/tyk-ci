output "shared_efs" {
  value = aws_efs_file_system.shared.id
}

# Used by infra.tf
output "kms" {
  value = aws_kms_key.cd.arn
}
