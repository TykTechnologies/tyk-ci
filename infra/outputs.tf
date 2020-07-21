output "mongo_host" {
  value       = aws_instance.mongo.private_ip
  description = "Shared with all environments"
}

output "bastion" {
  value       = aws_eip.bastion.public_dns
  description = "Bastion host EIP"
}
