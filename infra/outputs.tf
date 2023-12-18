output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC for infra"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "CIDR block of infra VPC"
}

output "zone-id" {
  value       = aws_route53_zone.dev_tyk_tech.zone_id
  description = "R53 zone id used by output "
}
