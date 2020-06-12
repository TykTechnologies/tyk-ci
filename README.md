# tyk-ci
Infrastructure definition for CI environments. This is the infra in which the integration images run for

- [tyk](https://github.com/TykTechnologies/tyk/actions?query=workflow%3A%22Integration+image%22 "gw")
- [tyk-analytics](https://github.com/TykTechnologies/tyk-analytics/actions?query=workflow%3A%22Integration+image%22 "db")
- [pump](https://github.com/TykTechnologies/tyk-pump/actions?query=workflow%3A%22Integration+image%22)

See <infra/default.tfvars> for the region, vpc subnet, etc.

## Network
Given a vpc cidr of 10.91.0.0/16, we create,
- a private 10.91.100.0/24
- a public 10.91.1.0/24 
subnets in one interpolated az of the region.

## Registry
[Registries](https://eu-central-1.console.aws.amazon.com/ecr/repositories?region=eu-central-1 "eu-central-1") are created with mutable tags and no automated scanning.

## Users
IAM users are created per-repo and given just enough access to access their repo with an inline policy. The users can login, push and pull images for just their repo. 

The access key\_ids and secrets are stored in the terraform state. Use `terraform output` to get the values to put into Github secrets.

## Mongo
Adds the newest bitnami mongo image (4.2 in June 2020) on a `t3.micro` instance.

## EFS
This is used to hold all the configuration data requierd for the services. This is mounted on the mongo instance as well as _all_ the containers. To repeat, the same fs is mounted on all containers.

## Bastion
Adds a bastion host in the public subnet with alok's key.

## TODOs
- add a permission boundary on the IAM users (paranoia)

## Aliases

``` shell
tf=terraform
tfA='terraform apply -var-file=$(terraform workspace show).tfvars'
tfa='[ -f out.plan ] && terraform apply out.plan || echo no plan'
tfp='terraform plan -var-file=$(terraform workspace show).tfvars -out out.plan'
tfv='terraform validate'
tfw='terraform workspace'
```
