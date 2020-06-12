output "cmaster" {
  value = "aws_instance.master.public_dns"
  description = "Public IP of Concourse master"
}

output "internal_network" {
  value = "aws_subnet.int1"
  description = "Access only to workers"
}

output "external_network"  {
  value = "aws_subnet.ext1"
  description = "Access to internet"
}
