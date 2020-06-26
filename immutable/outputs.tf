output "cfssl_efs" {
  value = aws_efs_file_system.cfssl.id
  description = "Shared with all environments"
}

output "config_efs" {
  value = aws_efs_file_system.config.id
  description = "Shared with all environments"
}
