# Tyk PKI

This is where the PKI infra for CI/CD resides.

## Generating the CA

There is a self-signed root CA which is used for all resources and for revocations.

``` shellsession
% cfssl gencert -initca rootca/csr.json | cfssljson -bare root
```

will generate `root-key.pem`, `root.pem`, and `root.csr` (for cross-signing).

Policies are defined in `rootca/config.json` for *server*, *peer*, and *client* roles. The authentication key can be generated with `openssl rand -hex 16` and set in `CFSSL_API_KEY`. A Dockerfile to provision the newest [cfssl](https://github.com/cloudflare/cfssl) is in `ca`.

To build and run the image, a Makefile is provided. Use it as,

``` shellsession
% cd ca
% make build && make run API_KEY=8b077934696760296d0feb688df571cf
docker build -t tykio/ca .
Sending build context to Docker daemon  18.43kB
Step 1/12 : FROM golang:latest AS builder
 ---> 00d970a31ef2
Step 2/12 : ENV GOPATH "/go"
 ---> Using cache
 ---> 7a0736831c31
Step 3/12 : RUN CGO_ENABLED=0 go get -u github.com/cloudflare/cfssl/cmd/...
 ---> Using cache
 ---> 950954c59e8f
Step 4/12 : FROM alpine:latest
 ---> a24bb4013296
Step 5/12 : RUN apk --no-cache add ca-certificates
 ---> Using cache
 ---> 8af72c97edaa
Step 6/12 : COPY --from=builder /go/bin/* /usr/local/bin/
 ---> Using cache
 ---> 9acf4005a5ed
Step 7/12 : ENV PATH "${PATH}:/usr/local/bin"
 ---> Using cache
 ---> 1af45ceab4bf
Step 8/12 : EXPOSE 8888
 ---> Using cache
 ---> 5a487bcade9a
Step 9/12 : VOLUME /cfssl
 ---> Using cache
 ---> 3540b894e771
Step 10/12 : WORKDIR /cfssl
 ---> Using cache
 ---> d4b4e63e48be
Step 11/12 : ENTRYPOINT [ "cfssl", "serve", "-address=0.0.0.0", "-port=8888", "-ca=rootca.pem", "-ca-key=rootca-key.pem", "-config=config.json" ]
 ---> Running in 7f6519f9ec87
Removing intermediate container 7f6519f9ec87
 ---> c43c183d692c
Step 12/12 : CMD [ "-loglevel", "1" ]
 ---> Running in cf8052780dcf
Removing intermediate container cf8052780dcf
 ---> 2b23d4a160e7
Successfully built 2b23d4a160e7
Successfully tagged tykio/ca:latest
docker run --name ca --detach --publish 127.0.0.1:8888:8888 -v /home/alok/work/tyk/src/tyk-ci/ca/rootca:/cfssl -e CFSSL_API_KEY=8b077934696760296d0feb688df571cf tykio/ca -loglevel 0
ab79856ec0f0478a3c4e80bac2c3f19ac1d3f329d6f2f345dd0c75828b4194f3
```

Pairs are valid for a year (8760h).

## Generating a key pair

Define the request in `csr.json` as in `ca/cd`.

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

Then the config to obtain a signature from the remote ca.

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
            "key": "env:CFSSL_API_KEY",
            "type": "standard"
        }
    },
    "remotes": {
        "caserver": "localhost:8888"
  }
}
```

Now request a pair to be signed using the server profile.

``` shell
% CFSSL_API_KEY=8b077934696760296d0feb688df571cf cfssl gencert -profile=server -loglevel=0 -config config.json csr.json | cfssljson -bare server
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

# What's not checked in

- keys
- certs

# What's checked in

- CSR definitions in JSON form
- policies
