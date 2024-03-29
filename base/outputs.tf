output "shared_efs" {
  description = "EFS that is provided to all tasks"
  value       = aws_efs_file_system.shared.id
}

output "cd_ter" {
  description = "ARN of the task execution role for CD tasks"
  value       = aws_iam_role.ter.arn
}

# Used by infra.tf
output "kms" {
  value = aws_kms_key.cd.arn
}

output "key_name" {
  value       = aws_key_pair.devacc.key_name
  description = "Key pair for EC2 instances. Private key in devacc.pem."
}
