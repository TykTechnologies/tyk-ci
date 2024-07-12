# Automated Testing

This directory hosts the automated testing infrastructure and code. Within each repo there are CI tests which are meant to quickly give feedback on PRs.

# Testing using tyk-automated-tests

Tyk can be deployed in many ways. A deployment is modelled by a compose file. `pro.yml` models a standard Tyk Pro installation.

## Directory structure
```
auto
├── deps.yml           # dependencies that can be reused between deployment models in a Pro deployment
├── pro.yml            # compose file defining the Tyk components in a Pro deployment
├── deps_pro-ha.yml    # dependencies that can be reused between deployment models in a Pro-HA deployment
├── pro-ha.yml         # compose file defining the Tyk components in a Pro-HA deployment
├── {mongo,postgres,..}.yml  # composable compose for 
├── pro/               # Tyk configs passed to services in pro.yml
├── pro-ha/            # Tyk configs passed to services in pro-ha.yml
├── confs/             # env var based config settings to override behaviour
├── local-*.env        # Env vars here can be set in the Tyk compose services by setting env_file=<file>
```

The configuration for the tyk components are provided via config files and env variables. The config files are used as the default configuration and behaviour can be overridden using environment variables in `confs/` or `local-*.env`.

# Setup for local environment

## Step 1: AWS integration account credentials
You need an access token and a functional AWS CLI with the sub-account to pull CI images from AWS ECR. There is [a confluence page](https://tyktech.atlassian.net/wiki/spaces/EN/pages/1683030062/AWS+SSO+How-to) that explains how to obtain and configure this credentials, also you may have to reach ITS if your user is not listed in order to get access granted to AWS integration account.
Once you have your credentials ready and the CLI functional, you can login with:
``` shellsession
% aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 754489498669.dkr.ecr.eu-central-1.amazonaws.com
```

## Step 2: Required software

### Install docker compose plugin or above (not docker-compose)
Follow the installation guide [here](https://docs.docker.com/compose/install/)

### Python Setup
Python is required for running the pytest framework. As of now, the required version is 3.7.16 (as specified in Pipfile). If you wish to maintain multiple Python versions on your laptop and switch among them, we recommend using Pyenv. Follow the instructions below for Pyenv installation on macOS.

### Installing pyenv on macOS

```bash
##### Step 1: Install Homebrew
# If you don't have Homebrew installed, run the following command in your terminal:

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && brew install pyenv

##### Step 2: Add pyenv to Shell
# Add the following to your shell configuration file (e.g., `~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`):

export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

#Restart your shell or run `source <config-file>` to apply the changes.

##### Step 3: Install required Python version
pyenv install 3.7.16

##### Step 4: Set Global Python Version
pyenv global 3.7.16

##### Step 5: Verify Installation
python --version
```

You should see `Python 3.7.16` in the output.
That's it! You've successfully installed `pyenv` on macOS and set the Python version to 3.7.16.

## Step 3: Prefill required environment variables
Navigate to ci/auto/master.env and fill in the following variables: pull_policy, TYK_DB_LICENSEKEY, TYK_MDCB_LICENSE

``` env
pull_policy=always
TYK_DB_LICENSEKEY=<PLACE A VALID DASHBOARD LICENSE HERE>
TYK_MDCB_LICENSE=<PLACE A VALID MDCB LICENSE HERE>
```

## Step 4: Prepare docker for environment creation
It's recommended to clean up your Docker environment before creating it for the first time. Run the following command to delete any dangling (unused) images, volumes, and containers:

```bash
docker system prune --volumes
```

# Run local environment : [Automated Task file](https://taskfile.dev/installation/)
This automation simplifies selecting different test scenarios. It sets up a `Pro` or `Pro-HA` installation using the master branch for all components by default. Note that it does not build the images but relies on release.yml in the repo having already pushed the images to ECR.

## Prerequisite
### Install taskfile utility
```brew install go-task```

### Export AWS credentials
Execute the `## Step 1: AWS integration account credentials` setup guide step if you have not done so already.

## How to use
Navigate to the ci/auto folder and execute the following steps:

### `Login`
This step performs a docker login against the ECR private repository to download the required CI images.
``` bash 
task login
```

### `Create  yout first environment`
Ensure no volumes are left created from older environments. You can do this using docker volume prune.
``` bash
task local FLAVOUR=pro DB=mongo44 VARIATION=murmur64
```

### `Destroy your environment`
It's essential to use the same parameters used for creation while deleting the environment.
``` bash
task clean FLAVOUR=pro DB=mongo44 VARIATION=murmur64
```

### Avilable combinations
These are all the available combinations. The framework can be extended easily for advanced users. New guides will be released for this subject during the adoption phase.
``` bash
DB = [mongo44, postgres15]
VARIATION = [murmur64, sha256]
FLAVOUR = [pro, pro-ha]
```

# Run tests
Tests are run locally by executing the **pytest** framework binary from your CLI. This allows you to develop or change the tests locally without the need to generate a new image for **tyk-automated-tests**, which is used during remote execution on GitHub. To run the tests, you need to set up pytest along with pipenv to hit the multiple endpoints of the compose environment containers.

## Pytest Setup
Execute the following inside the `tyk-automated-tests` repo root folder
``` bash
pip install pipenv
cd ci/auto
pipenv install
pipenv shell
export USER_API_SECRET=<VALUE TAKEN FROM BOOTSTRAP OUTPUT ON ENV CREATE>
```

While deploying a `FLAVOUR=pro-ha` environment is crucial to export the `USER_API_SECRET` variable before executing any test. This variable is used by the **pytest** framework tests to send authorized request to the dashboard.

![Alt text](image.png)

## Pytest Run
Usage:
``` shellsession
$ pytest -c pytest_local.ini --ci [ DIR | FILE | -m "markers" | -k "test_name" ]
```
The trick is to determine which tests to run. You can find the available markers in any of the `pytest.ini` files at the root of the repo. These markers group tests based on the product.

``` shell
markers =
    local: marks tests which can be executed only on local
    mdcb: marks tests which can be executed only on mdcb
    sql: marks tests which cannot run on sql env
    gw: marks tests which can be executed only on gateway
    dash_admin: marks tests which can be executed for dashboard admin api
    dash_api: marks tests which can be executed for dashboard api
    graphql: marks tests which can be executed for testing graphql features
    portal: marks tests which can be executed for testing portal
    dind: marks tests which use docker in docker for assertion
```

## Examples
The following examples guide you on how to mix and match variations. The combinations deployed remotely on GitHub are `FLAVOUR=pro-ha` `DB=postgres15` and `FLAVOUR=pro-ha` `DB=mongo44` as of today. To reproduce the same tests locally, use examples **#3** and **#4** but keep in mind you need to create the environments accordingly.

``` bash
# Example #1 for full test on FLAVOUR=pro DB=mongo44 (not very usual)
$ pytest -c pytest_local.ini --ci -m "not local and not dind and not mdcb"

# Example #2 for full test on FLAVOUR=pro DB=postgres15 (not very usual)
$ pytest -c pytest_local.ini --ci -m "not local and not dind and not mdcb and not sql"

# Example #3 for full test on FLAVOUR=pro-ha DB=mongo44 (LIVE ON-GITHUB)
$ export USER_API_SECRET=<COPY VALUE FROM BOOTSTRAP OUTPUT>
$ pytest -c pytest_local.ini --ci -m "not local and not dind"

# Example #4 for full test on FLAVOUR=pro-ha DB=postgres15 (LIVE ON-GITHUB)
$ export USER_API_SECRET=<COPY VALUE FROM BOOTSTRAP OUTPUT>
$ pytest -c pytest_local.ini --ci -m "not local and not dind and not sql"

```
test auto gates