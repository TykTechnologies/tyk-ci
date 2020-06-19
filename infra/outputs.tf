output "mongo_host" {
  value = aws_instance.mongo.private_ip
  description = "Shared with all environments"
}

output "config_efs" {
  value = aws_efs_file_system.config.id
  description = "Shared with all environments"
}

output "region" {
  value = var.region
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
  description = "gateway"
}

output "tyk-pump" {
  value = map("key", aws_iam_access_key.integration["tyk-pump"].id,
    "secret", aws_iam_access_key.integration["tyk-pump"].secret,
    "ecr", aws_ecr_repository.integration["tyk-pump"].repository_url)
  description = "gateway"
}
