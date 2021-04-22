# Base infra

- ECR
- access keys and secrets for 
  + ECR push pull for github actions
  + shared account with access to the images and logs
  + IAM roles for gromit
- efs volumes

Kept outside the infra module as they have a different lifecycle from the other infra components. Infra can be destroyed if needed. This directory hosts all the components that need persistance.

Check `terraform output`. 

This is the state that the integration image Github workflows depend
on. State is persisted remotely in [Terraform
Cloud](https://app.terraform.io/app/Tyk/workspaces/base-prod/settings/general
"ask devops for access").
