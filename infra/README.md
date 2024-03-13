# Infrastructure

Contains the ephemeral infrastructure for persistent environments. See `prod.auto.tfvars` for the inputs that have been used. 

This depends on EFS volumes from the `base` workspace on [Terraform Cloud](https://app.terraform.io/app/Tyk/workspaces/base-prod/settings/general). These manifests are in the <../base> dir.

An exception to ephemeral instances is _deptrack_ which is maintained as pet. Terraform brings up the instance with docker compose installed and configured. Persistence is left to an EFS volume which is mounted in /shared.

# Architecture

All EC2 instances may be upgraded along with normal operations because a new AMI was released.

Everything else is an ECS cluster with CloudMap for internal service discovery and R53 for external DNS. All containers are with the `.internal` DNS domain. tyk and tyk-analytics are exposed to the internet. Nothing else is. 

## Internal operations
All persistance is based on an EFS volume which is mounted to `/config` for all containers. This contains the config files and is also mounted on the bastion. ssh there to make edits.

# External dependencies

- TFCloud API token as a secret, replace ARN where-ever used
- `CLOUDFLARE_API_TOKEN`
