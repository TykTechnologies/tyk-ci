# Immutable infra

This is kept outside the infra module as the configs and cfssl keys have a different lifecycle from the other infra components.

Check `terraform output` for the filesystem ids. 

State is persisted remotely in [Terraform Cloud](https://app.terraform.io/app/Tyk/workspaces/immutable/settings/general "ask devops for access").
