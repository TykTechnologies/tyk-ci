# Infrastructure

This is what the developer environments run on. State is persisted remotely in [Terraform Cloud](https://app.terraform.io/app/Tyk/workspaces/infra-prod/settings/general "ask devops for access") and is available in the *Integration Image* github workflow. 

Outputs persisted to this state should be very carefully considered as they are almost public. We take some care to mask secrets in the workflow but that is a figleaf.

See `prod.tfvars` for inputs that have been used. 

This depends on EFS volumes from the `base` workspace on [Terraform Cloud](https://app.terraform.io/app/Tyk/workspaces/base-prod/settings/general).

# External dependencies

- ssh keypair
- TFCloud API token as a secret, replace ARN where-ever used
