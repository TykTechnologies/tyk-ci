output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC for infra"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "CIDR block of infra VPC"
}
