# Tyk CI/CD

Infrastructure definition for CI/CD environments.

## Base
Contains the eesources that require persistence or have lifecycle separate from infra. Stored in a separate state on [Terraform Cloud](https://app.terraform.io/app/Tyk/workspaces/base-euc1/states).

Contents:
- vpc 
- ECR repos
- Shared EFS filesystem
- RDS PostgreSQL

See [base/*.auto.tfvars](base/*.auto.tfvars) for the actual values being used right now.

### Network
Given a vpc cidr of 10.91.0.0/16, we create,
- a /24 private subnet per az
- a /24 public subnet per az
- a nat gw for internet access from the private subnets
- igw for the public subnets

### ECR
[Registries](https://eu-central-1.console.aws.amazon.com/ecr/repositories?region=eu-central-1 "eu-central-1") are created with mutable tags and no automated scanning.

## Infra
Contains the ephemeral components. In theory, this could be deleted and re-created with no data loss. Imports the state from <base/> as a remote state. 

### Bastion
Adds a bastion host in the public subnet with alok's key. The EFS filesystem are mounted here.

### deptrack

DependencyTrack in ECS. It uses the shared RDS instance from <base>. Available at [https://deptrack.dev.tyk.technology](https://deptrack.dev.tyk.technology "deptrack").

### windmill.dev

OSS version deployed on ECS on EC2. Available at [https://windmill.dev.tyk.technology](https://windmill.dev.tyk.technology "windmill").
