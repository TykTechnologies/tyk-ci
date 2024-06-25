force
# Tyk CI/CD

Infrastructure definition for CI/CD environments.

To add a new repo to CI,
- add the repo to `REPOS` in [wf-gen/common.zsh](wf-gen/common.zsh)
- run [wf-gen/prs.zsh](wf-gen/prs.zsh) for all repos
- get all your PRs merged

To add a new repo to CD, 
- add it to the `local.repos` in [base/base.tf](base/base.tf)
- plan, apply there
- add a sensible default value to a new variable for the repo in [infra/variables.tf](infra/variables.tf)
- add it to `local.repos` in [infra/infra.tf](infra/infra.tf)
- plan, apply there
- add a definition of the service to [devenv/terraform](https://github.com/TykTechnologies/gromit/tree/master/devenv/terraform) in the gromit repo
- make new release of gromit
- let [the CD on this repo](.github/workflows) deploy the new gromit release

To manage the meta-automation which keeps the automation managed by `prs.zsh` in sync across release branches,
- review [wf-gen/meta.zsh](wf-gen/meta.zsh)
- run it

## Base
Contains the AWS Resources that require privileged access like IAM roles. These resources have a lifecycle separate from the infra and are stored in a separate state on [Terraform Cloud](https://app.terraform.io/app/Tyk/workspaces/base-euc1/states).

Contents:
- vpc 
- ECR repos
- ECS Task roles
- EFS filesystems for Tyk config (`config`) and Tyk PKI (`certs`)

See [base/*.auto.tfvars](base/*.auto.tfvars) for the actual values being used right now.

### Network
Given a vpc cidr of 10.91.0.0/16, we create,
- a /24 private subnet per az
- a /24 public subnet per az
- a nat gw for internet access from the private subnets
- igw for the public subnets

### ECR
[Registries](https://eu-central-1.console.aws.amazon.com/ecr/repositories?region=eu-central-1 "eu-central-1") are created with mutable tags and no automated scanning.

### IAM Users
IAM users are created per-repo and given just enough access to access their repo with an inline policy. The users can login, push and pull images for just their repo. 

The access key\_ids and secrets are stored in the terraform state. Use `terraform output` to see the values.

### EFS
This is used to hold all the configuration data requierd for the services. This is mounted on the mongo instance as well as _all_ the containers. To repeat, the same fs is mounted on all containers.

## TODOs
- add a permission boundary on the IAM users (paranoia)

## Infra
Contains the components required to support a Tyk installation. These resources have a lifecycle separate from the developer environments and are stored in a separate state on [Terraform Cloud](https://app.terraform.io/app/Tyk/workspaces/dev-euc1/states).

### Bastion
Adds a bastion host in the public subnet with alok's key. The EFS filesystems are mounted here. The `tyk` group has access to the config directories in `/config`. Login to the bastion to change the config or to create new config groups.

### Mongo
Adds the newest bitnami mongo image (4.2 in June 2020) on a `t3.micro` instance.

# Tyk PKI
In `certs`.

## Generating the CA

There is a self-signed root CA which is used for all resources and for revocations.

``` shellsession
% cd rootca
% cfssl gencert -initca csr.json | cfssljson -bare rootca
```

will generate `rootca-key.pem`, `rootca.pem`, and `rootca.csr` (for cross-signing).

Policies are defined in `rootca/config.json` for *server*, *peer*, and *client* roles. The authentication key can be generated with `openssl rand -hex 16` and set in `CFSSL_API_KEY`. A Dockerfile to provision the newest [cfssl](https://github.com/cloudflare/cfssl) is in `ca`.

## Generating an intemediate CA

``` shellsession
% cd sshca
# Generate pair
% cfssl genkey -initca csr.json | cfssljson -bare ssh
# Sign cert with root CA
% cfssl sign -ca=../rootca/rootca.pem -ca-key=../rootca/rootca-key.pem -config=config.json -profile peer ssh.csr | cfssljson -bare ssh
```

## Generating an mTLS pair

### Server

Define the request in `csr.json`.

``` json
{
    "CN": "cd.tyk.technologies",
    "hosts": [
        "cd.dev.tyk.technologies",
        "localhost"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "UK",
            "L": "London",
            "O": "Tyk Technologies",
            "OU": "Devops",
            "ST": "Greater London"
        }
    ]
}
```

Now request for the certpair to be signed using the server profile by using the config in `cfssl-sign.json`.

``` shell
% CFSSL_API_KEY=xxxxx cfssl gencert -profile=server -config cfssl-sign.json csr.json | cfssljson -bare server
2020/06/26 13:11:29 [DEBUG] loading configuration file from config.json
2020/06/26 13:11:29 [DEBUG] match remote in profile to remotes section
2020/06/26 13:11:29 [DEBUG] match auth key in profile to auth_keys section
2020/06/26 13:11:29 [DEBUG] validating configuration
2020/06/26 13:11:29 [DEBUG] validate remote profile
2020/06/26 13:11:29 [DEBUG] profile is valid
2020/06/26 13:11:29 [DEBUG] configuration ok
2020/06/26 13:11:29 [INFO] generate received request
2020/06/26 13:11:29 [INFO] received CSR
2020/06/26 13:11:29 [INFO] generating key: rsa-2048
2020/06/26 13:11:29 [DEBUG] generate key from request: algo=rsa, size=2048
2020/06/26 13:11:29 [INFO] encoded CSR
2020/06/26 13:11:29 [DEBUG] validating configuration
2020/06/26 13:11:29 [DEBUG] validate remote profile
2020/06/26 13:11:29 [DEBUG] profile is valid
2020/06/26 13:11:29 [DEBUG] validating configuration
2020/06/26 13:11:29 [DEBUG] validate remote profile
2020/06/26 13:11:29 [DEBUG] profile is valid
```

This will give you `server-key.pem`, `server.pem` and `server.csr`. Use these as you will.

### Client

The `csr.json` for the server can be re-used but you'll want to remove the hests entries. Or start with `cfssl print-defaults csr > csr.json`.

Then, request for signing as above except use `-profile=client`. 

# What's not checked in

- keys

# What's checked in

- certs
- CSR definitions in JSON form
- signing policy for `cfssl.dev.tyk.technology`
