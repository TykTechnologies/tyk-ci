# Infrastructure

This is what the developer environments run on. State is persisted remotely in [Terraform Cloud](https://app.terraform.io/app/Tyk/workspaces/infra-prod/settings/general "ask devops for access") and is available in the [Release Engineering workflows](https://tyktech.atlassian.net/wiki/spaces/EN/pages/449708061/Release+Engineering).

Outputs persisted to this state should be very carefully considered as they are pratically public. We take some care to mask secrets in the workflow but that is a figleaf.

The AWS access keys for each repo are only for that repo. 

See `prod.tfvars` for inputs that have been used. 

This depends on EFS volumes from the `base` workspace on [Terraform Cloud](https://app.terraform.io/app/Tyk/workspaces/base-prod/settings/general). These manifests are in the <../base> dir.

# Architecture

Bastion and the Mongo hosts are ec2 instances. All EC2 instances may be upgraded along with normal operations because a new AMI was released.

Everything else is an ECS cluster with CloudMap for internal service discovery and R53 for external DNS. All containers are with the `.internal` DNS domain. tyk and tyk-analytics are exposed to the internet. Nothing else is. 

## Internal operations
Automated operations and housekeeping are conducted by the `internal` cluster. When the release workflow is triggered in any repo, if it completes successfully, a notification is made to an API defined in the devops account on Classic Cloud. This API turns the authtoken based authentication used between github and the endpoint to mTLS authentication to `gromit serve` running in the internal cluster. There is no persistance here.

All persistance is based on an EFS volume which is mounted to `/config` for all containers. This contains the config files and is also mounted on the bastion. ssh there to make edits.

Repo state reported to the `newBuild` endpoint is persisted in a DynamoDB table `DeveloperEnvironments`. `gromit serve` is responsible for state management of this table and is the only writer.

`gromit sow` is a Fargate scheduled task that looks `DeveloperEnvironments` every 37 mins and makes required updates. The updates are made by terraform. There is an S3 bucket `terraform-state-dev` env that is used for remote state. Each environment is a workspace. Go to the <devenv/terraform> directory in the [gromit](/TykTechnologies/gromit) repo to inspect and operate on it.

`gromit reap` is a Fargate scheduled task that looks in `DeveloperEnvironments` every day and deletes environments that are not needed.

All processing can be suspended by `touch`ing a file `/config/noprocess` on the bastion.

`chitragupta`, the record keeper of the gods is a Fargate scheduled task that looks at all the running environments every 13 minutes and updates their DNS records in Route53. This is a hack as CloudMap does not work for external DNS.

# External dependencies

- ssh keypair
- TFCloud API token as a secret, replace ARN where-ever used
- CLOUDFLARE_TOKEN
