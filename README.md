# tyk-ci
Infrastructure definition for CI environments. This is the infra in which the integration images run for

- [tyk](https://github.com/TykTechnologies/tyk/actions?query=workflow%3A%22Integration+image%22 "gw")
- [tyk-analytics](https://github.com/TykTechnologies/tyk-analytics/actions?query=workflow%3A%22Integration+image%22 "db")
- [pump](https://github.com/TykTechnologies/tyk-pump/actions?query=workflow%3A%22Integration+image%22)

See <infra/*.auto.tfvars> for the region, vpc subnet, etc.

## Network
Given a vpc cidr of 10.91.0.0/16, we create,
- a /24 private subnet per az
- a /24 public subnet per az
- a nat gw for internet access from the private subnets
- igw for the public subnets

## Registry
[Registries](https://eu-central-1.console.aws.amazon.com/ecr/repositories?region=eu-central-1 "eu-central-1") are created with mutable tags and no automated scanning.

## Users
IAM users are created per-repo and given just enough access to access their repo with an inline policy. The users can login, push and pull images for just their repo. 

The access key\_ids and secrets are stored in the terraform state. Use `terraform output` to see the values.

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
tfA='terraform apply'
tfa='[ -f out.plan ] && terraform apply out.plan || echo no plan'
tfp='terraform plan -out out.plan'
tfv='terraform validate'
tfw='terraform workspace'
```
## PKI

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
