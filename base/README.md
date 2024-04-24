# Base infra

- ECR
- Github OIDC
- efs volumes
- RDS
- VPC and subnets

Kept outside the infra module as they have a different lifecycle from the other infra components. Infra can be destroyed if needed. This directory hosts all the components that need persistance.

Use the Makefile to see the resource targetting that is required to bring this env up from scartch. `terraform output` will show you the outputs that are available for use in other states.
