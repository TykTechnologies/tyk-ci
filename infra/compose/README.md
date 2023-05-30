**This is no longer used as Compose for ECS will be retired in Nov 2023**

# Step CA
Initialise the CA by generating root and intermediate certificates. This needs be done only _once_ per CA. In Tyk's case do the initialisation locally on your laptop and then copy over the directory with the generated files onto the EFS that `smallstep/step-ca` will use as a volume.

With an empty directory called `step` in your current working directory,
``` shellsession
$ docker run -it --mount type=bind,source=$(pwd)/step,target=/home/step \
    -p 9000:9000 \
    -e "DOCKER_STEPCA_INIT_NAME=Tyk" \
    -e "DOCKER_STEPCA_INIT_DNS_NAMES=ca.tyk.technology,localhost" \
    -e "DOCKER_STEPCA_INIT_REMOTE_MANAGEMENT=true" \
  smallstep/step-ca
```

The (auto-generated) password that the certificate keys are encrypted with will be shown in plaintext. This is required for `step-ca` to start. Add it into the file referenced by the `ca-key-pass` secret in the compose file.

# Docker Compose

Compose has [evolved](https://docs.docker.com/compose/compose-v2/) over the years which makes Google results confusing if you are not aware of the context. To work with ECS contexts from `docker compose` we need _Docker Compose "Cloud Integrations"_.

## Installation
Docker Desktop has the required plugins bundled so nothing further needs to be done. If you have [Docker Engine](https://docs.docker.com/engine/install/) then,

1. Get the latest binary for your architecture from <https://github.com/docker/compose-cli/releases>.
2. Rename this to `docker` and place it somewhere where it will be found _before_ the Docker Engine `docker` binary.
3. Make the Docker Engine `docker` binary available as `com.docker.cli` somewhere in your path.

### Verification

``` shellsession
$ docker version
Client: Docker Engine - Community
 Cloud integration: v1.0.30
 ....
```

## Configuration
1. Sign into AWS via the CLI (v2 recommended, but v1 works too)
2. `unset AWS_PROFILE`, this is workaround for `AssumeRoleTokenProviderNotSetError`
2. `docker context create ecs <name>`, using the same name as the AWS profile name makes it easier
3. `docker context use <name>`

### AssumeRoleTokenProviderNotSetError
Not really sure what is the problem or if it is only caused by [acp](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/aws/aws.plugin.zsh#L31). If you are bitten by this, all `docker` commands will break. To fix, change the `currentContext` key in `~/.docker/config.json`.
