output "bastion_host" {
  value = aws_instance.bastion.public_ip
  description = "Connect with ec2-user"
}

output "region" {
  value = var.region
  description = "Region in which the dev env is running"
}

# Keep it explicit to make sure that the correct
# value is populated in the correct place

output "tyk_key_id" {
  value = aws_iam_access_key.integration["tyk"].id
  description = "Key ID for tyk repo"
}

output "tyk-analytics_key_id" {
  value = aws_iam_access_key.integration["tyk-analytics"].id
  description = "Key ID for tyk-analytics repo"
}

output "tyk-pump_key_id" {
  value = aws_iam_access_key.integration["tyk-pump"].id
  description = "Key ID for tyk-pump repo"
}

output "tyk_secret_key" {
  value = aws_iam_access_key.integration["tyk"].secret
  description = "Secret key for tyk repo"
  sensitive = true
}

output "tyk-analytics_secret_key" {
  value = aws_iam_access_key.integration["tyk-analytics"].secret
  description = "Secret key for tyk repo"
  sensitive = true
}

output "tyk-pump_secret_key" {
  value = aws_iam_access_key.integration["tyk-pump"].secret
  description = "Secret key for tyk repo"
  sensitive = true
}
