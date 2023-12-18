# Base infra

- ECR
- Github OIDC
- efs volumes

Kept outside the infra module as they have a different lifecycle from the other infra components. Infra can be destroyed if needed. This directory hosts all the components that need persistance.

Check `terraform output`.
