output "mongo_host" {
  value       = aws_instance.mongo.private_ip
  description = "Shared with all environments"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC for infra"
}

output "r53_hosted_zoneid" {
  value = aws_route53_zone.dev_tyk_tech.zone_id
  description = "Zone ID for dev.tyk.technology"
}
