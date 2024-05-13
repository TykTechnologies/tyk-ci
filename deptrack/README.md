Keeping deptrack in its own state to minimise its blast radius. It has access to the base state outputs.

The database provisioning is manual. The reasons it was not maintained as IaC are:
- the terraform provider [requires the instance to available](https://github.com/cyrilgdn/terraform-provider-postgresql/issues/81) where the manifests are being processed
- remote_exec requires management of ssh access to the bastion.

So, if you have deleted the deptrack db or role, you will have to create it _before_ running this manifest. The role password is expected in the SSM parameter `/deptrack/db_pass`.

## Creating DB objects

```
postgres=> create role deptrack with nocreatedb nocreaterole login password 'supersekret';
CREATE ROLE
postgres=> create database deptrack with owner deptrack encoding 'UTF8';
ERROR:  must be member of role "deptrack"
postgres=> grant deptrack to master;
GRANT ROLE
postgres=> create database deptrack with owner deptrack encoding 'UTF8';
CREATE DATABASE
```

## Applying manifests
To apply the manifests from scratch, login to AWS on your CLI. You will need at least PowerUser access to the devacc (754489498669) sub-account. Then use the the usual incantation:

```
terraform init && terraform plan && terraform apply
```

## Access
Via bastion.dev.tyk.technology. Add your key to the [cloudinit template](https://github.com/TykTechnologies/tyk-ci/blob/master/infra/bastion-cloudinit.yaml.tftpl#L19) or use the devacc key.
