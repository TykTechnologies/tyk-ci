# Tyk PKI

This is where the PKI infra for CI/CD resides.

## Generating the CA

There is a self-signed root CA which is used for all resources and for revocations.

``` shellsession
% cfssl gencert -initca root-ca.csr.json | cfssljson -bare root
```

will generate `root-key.pem`, `root.pem`, and `root.csr` (for cross-signing).

A policy is defined in `root-policy.json`. This file contains the authentication key that will be used to talk to the CA. You can generate a random 16-byte hex string with `openssl rand -hex 16`.

Pairs are valid for a year (8760h).

## Generating a key pair

Define the request. For example:

``` json
{
  "hosts": [
    "db1.ci.tyk.technologies"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "Germany",
      "L": "Frankfurt",
      "O": "Tyk dev envs",
      "OU": "Devops",
      "ST": "Frankfurt"
    }
  ]
}
```

Now define a policy. Assuming that cfssl is serving on `ca.ci.tyk.technologies`, it might look something like,

``` json
{
  "signing": {
    "default": {
      "auth_key": "key1",
      "remote": "caserver"
    }
  },
  "auth_keys": {
    "key1": {
    "key": <16 byte hex key from root-policy.json>,
    "type": "standard"
    }
  },
  "remotes": {
    "caserver": “ca.ci.tyk.technologies:8888"
  }
}
```

Now request a pair:

``` shell
% cfssl gencert -config policy.json csr.json | cfssljson -bare db
```

This will give you `db-key.pem`, `db.pem` and `db.csr`. Use these as you will.

# What's not checked in

- policies
- keys
- certs

# What's checked in

- CSR definitions in JSON form
