# Base infra

- ECR
- access keys and secrets for ECR push pull for github actions
- efs volumes

Kept outside the infra module as they have a different lifecycle from
the other infra components.

Check `terraform output`. 

This is the state that the integration image Github workflows depend
on. State is persisted remotely in [Terraform
Cloud](https://app.terraform.io/app/Tyk/workspaces/base-euc1/settings/general
"ask devops for access").