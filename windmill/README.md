Keeping windmill in its own state to minimise its blast radius. It has access to the base state outputs.

The database provisioning is manual. The reasons it was not maintained as IaC are:
- the terraform provider [requires the instance to available](https://github.com/cyrilgdn/terraform-provider-postgresql/issues/81) where the manifests are being processed
- remote_exec requires management of ssh access to the bastion.

So, if you have deleted the windmill db or role, you will have to create it _before_ running this manifest. The role password is expected in the SSM parameter `/windmill/db_pass`.

## Creating DB objects
The RDS instance is not accessible from the internet. Use bastion.dev.tyk.technology which has psql installed. Add your key to the [cloudinit template](https://github.com/TykTechnologies/tyk-ci/blob/master/infra/bastion-cloudinit.yaml.tftpl#L19) or use the devacc key.

Obtain the DB host from the the AWS console or from `tf output` in `../base`. The master password is in SSM Parameter Store as `/base-prod/rds/master`.

```shellsession
$ psql -h postgres15.c1po6t6zkr9a.eu-central-1.rds.amazonaws.com -U master -W -d postgres
postgres=> create role windmill with nocreatedb nocreaterole login password 'supersekret';
CREATE ROLE
postgres=> create database windmill with owner windmill encoding 'UTF8';
ERROR:  must be member of role "windmill"
postgres=> grant windmill to master;
GRANT ROLE
postgres=> create database windmill with owner windmill encoding 'UTF8';
CREATE DATABASE
postgres=> CREATE ROLE windmill_user;
CREATE ROLE
postgres=> GRANT ALL PRIVILEGES ON DATABASE windmill TO windmill_user;
GRANT
postgres=> CREATE ROLE windmill_admin WITH BYPASSRLS;
CREATE ROLE
postgres=> GRANT windmill_user TO windmill_admin;
GRANT ROLE
postgres=> grant windmill_admin to windmill;
GRANT ROLE
postgres=> grant windmill_user to windmill;
GRANT ROLE
```

`windmill` is the user used to connect to the database.` windmill_user` and `windmill_admin` and users internal to windmill. The documentation requires giving windmill an RDS instance to itself. By creating these users externally, the shared RDS instance in <../base> can be used.

Construct the URL to access the DB in SSM as a SecureString with name `/windmill/db_url`. 

## Applying manifests
To apply the manifests from scratch, login to AWS on your CLI. You will need at least PowerUser access to the devacc (754489498669) sub-account. Then use the the usual incantation:

```
terraform init && terraform plan && terraform apply
```
