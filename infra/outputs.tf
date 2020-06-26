output "mongo_host" {
  value = aws_instance.mongo.private_ip
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
  description = "dashboard"
}

output "tyk-pump" {
  value = map("key", aws_iam_access_key.integration["tyk-pump"].id,
    "secret", aws_iam_access_key.integration["tyk-pump"].secret,
    "ecr", aws_ecr_repository.integration["tyk-pump"].repository_url)
  description = "pump"
}

output "int-service" {
  value = map("key", aws_iam_access_key.integration["int-service"].id,
    "secret", aws_iam_access_key.integration["int-service"].secret,
    "ecr", aws_ecr_repository.integration["int-service"].repository_url)
  description = "integration service"
}

output "cfssl" {
  value = map("key", aws_iam_access_key.integration["cfssl"].id,
    "secret", aws_iam_access_key.integration["cfssl"].secret,
    "ecr", aws_ecr_repository.integration["cfssl"].repository_url)
  description = "cfssl"
}
