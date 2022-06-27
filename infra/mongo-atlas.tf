// Mongo Atlas
module "tf-mongodbatlas" {
	# TBFixed once we ensure current module changes are compatible with ARA
	# source = "git::git@github.com:TykTechnologies/tf-mongodbatlas.git?ref=v0.1.0"
  source 							= "../modules/mongo"
	atlas_org_id 				= "5af0c475d383ad770ebc6e94"
	cluster_name 				= "integration"
	atlas_teams 				= []
	atlas_instance_size = "M10"
	atlas_region 				= "EU_CENTRAL_1"
	# aws_region required but not used anywhere really
	aws_region 					= "EU_CENTRAL_1"
	backup_enabled 			= false
	atlas_disk_size_gb 	= 10
	atlas_cidr 					= var.atlas_cidr
	atlas_allowed_cidrs = [module.vpc.vpc_cidr_block]
	default_labels 			= { terraform="true", creator="ermirizio" }
	admin_username 			= local.db_creds.username
	admin_password 			= local.db_creds.password
	# Peering
	peering_enabled			= true
	peering_aws_region 	= "eu-central-1"
	peering_aws_vpc_id 	= module.vpc.vpc_id
	peering_cidr				= module.vpc.vpc_cidr_block

}

// Peering - AWS side 
## Peering on both private and public route tables
## This is because we need instances sitting in public subnet (like bastion) to reach mongo

## Should we embeed this into mongo atlas module?
resource "aws_route" "peering-private" {
	route_table_id            = module.vpc.private_route_table_ids.0
  destination_cidr_block    = var.atlas_cidr
  vpc_peering_connection_id = module.tf-mongodbatlas.atlas_network_peering_connection_id
  depends_on                = [module.vpc.aws_route_table]
}

## Should we embeed this into mongo atlas module?
resource "aws_route" "peering-public" {
	route_table_id            = module.vpc.public_route_table_ids.0
  destination_cidr_block    = var.atlas_cidr
  vpc_peering_connection_id = module.tf-mongodbatlas.atlas_network_peering_connection_id
  depends_on                = [module.vpc.aws_route_table]
}


// Secrets
resource "aws_secretsmanager_secret" "mongo-pass" {
   name = "mongo_admin_pass"
}

resource "aws_secretsmanager_secret_version" "sversion" {
  secret_id = aws_secretsmanager_secret.mongo-pass.id
  secret_string = <<EOF
   {
    "username": "mongo",
    "password": "${random_password.password.result}"
   }
EOF
}

## Importing secret
data "aws_secretsmanager_secret" "mongo-pass" {
  arn = aws_secretsmanager_secret.mongo-pass.arn
}
## Importing secret version
data "aws_secretsmanager_secret_version" "creds" {
  secret_id = data.aws_secretsmanager_secret.mongo-pass.arn
}
 
## Storing into Locals
locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
}

## Random password generation for secret input
resource "random_password" "password" {
  length           = 16
  upper            = true
  lower            = true
  numeric          = true
  special          = true
  override_special = "!#$&*()-_=[]{}<>?" # Don't allow symbols, which are part of MongoDB conn string
}