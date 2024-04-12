output "shared_efs" {
  description = "EFS that is provided to CD tasks"
  value       = aws_efs_file_system.shared.id
}

output "deptrack_efs" {
  description = "EFS for Dependency Track"
  value       = aws_efs_file_system.deptrack.id
}

output "assets" {
  description = "ARN of S3 bucket containing logs, reports and other static assets"
  value       = aws_s3_bucket.assets.id
}

# Used by infra.tf
output "kms" {
  value = aws_kms_key.cd.arn
}

output "key_name" {
  value       = aws_key_pair.devacc.key_name
  description = "Key pair for EC2 instances. Private key in secrets.yaml."
}
