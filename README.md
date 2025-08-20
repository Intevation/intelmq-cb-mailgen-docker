# IntelMQ development environment

Use Docker-Compose to build up a complete development and test
environment for IntelMQ, Manager, fody, mailgen and webinput

### FOR DEVELOPMENT ONLY! CONTAINS INSECURE PLAINTEXT PASSWORDS!

## Contents

- [Introduction](#Introduction)
- [Building Packages](#building-packages)
- [Setup Scenarios](#setup-scenarios)
    - [Configuration env](#configuration-env)
    - [Scenario 1 ("Source")](#scenario-1-from-source-default)
    - [Scenario 2 ("Development")](#scenario-2-development-dev)
    - [Scenario 3 ("packages")](#scenario-3-local-packages-pkg)
    - [Scenario 4 ("full packages")](#scenario-4-repository-packages-full-pkg)
    - [General](#General)
    - [The Containers](#the-containers)
- [Using the applications](#using-the-applications)
    - [ContactDB](#contactdb)
    - [Mailgen](#mailgen)
    - [IntelMQ](#intelmq)
- [Tests](#tests)

## Introduction

This repository contains docker environments for building packages and using a full IntelMQ setup with different scenarios.

The following scenarios are supported:
1. Test-Setup with services build from source with a given revision (default is master)
1. Development-Setup with mounted source code for easy editing
1. Test-Setup with services build from package (file system)
1. Test-Setup with services build from package (repository)


## Building packages

Currently the build process supports Ubuntu 22.04 Jammy only and builds the following packages:

* intelmq-fody
* intelmq-fody-backend
* intelmq-mailgen
* intelmq-certbund-contact
* intelmq-webinput-csv
* intelmq-webinput-csv-backend

To start the build process use `./pkg/build-packages.sh`.
The script takes a couple of parameters given as environment variables.

* IMQ_BUILD_PACKAGES - List of packages to build
* IMQ_BUILD_RELEASE - Switch to build a release package (values are "yes" or "no")
* IMQ_BUILD_DIR - Destination directory for the resulting logs and packages (will be prefixed with current $HOME)

## Setup Scenarios

On the first startup, the two containers intelmq-database and intelmq-fody-backend seem to hang. The reason is that the data import for the contactdb takes some time and the fody backend waits for the import to finish.

Ports on the host machine for the applications and APIs:

* intelmq-manager: 1380 (path `/intelmq-manager`)
* intelmq-api: 1381 (not in all scenarios)
* intelmq-fody: 1382
* intelmq-fody-backend: 1340 (not in all scenarios)
* intelmq-webinput-csv: 1383
* intelmq-webinput-csv-backend: 1341 (not in all scenarios)

### Configuration env

The complete stack is mostly configured via the .env-file and has four 'sections'.

The first section configures the paths to development directories containing the source code of required components, which you will need to download in addition to this repository: [`intelmq`](https://github.com/certtools/intelmq), [`intelmq-api`](https://github.com/certtools/intelmq-api), [`intelmq-manager`](https://github.com/certtools/intelmq-manager), [`intelmq-fody`](https://github.com/Intevation/intelmq-fody), [`intelmq-fody-backend`](https://github.com/Intevation/intelmq-fody-backend), [`intelmq-webinput-csv`](https://github.com/Intevation/intelmq-webinput-csv), [`intelmq-certbund-contact`](https://github.com/Intevation/intelmq-certbund-contact), [`intelmq-mailgen`](https://github.com/Intevation/intelmq-mailgen)
```
# Mounted source directories in dev variant
DEV_INTELMQ_SRC=../intelmq
DEV_INTELMQ_API_SRC=../intelmq-api
DEV_INTELMQ_MANAGER_SRC=../intelmq-manager
DEV_FODY_SRC=../intelmq-fody
DEV_FODY_BACKEND_SRC=../intelmq-fody-backend
DEV_WEBINPUT_CSV_SRC=../intelmq-webinput-csv
DEV_CERTBUND_CONTACT_SRC=../intelmq-certbund-contact
DEV_MAILGEN_SRC=../intelmq-mailgen
```

The second section configures the paths to rules, templates and formats of CERT-BUND bots and mailgen. These paths are mounted in all scenarios. The content can be changed during runtime, but remember to restart bots on change.
```
# Mounted directories for rule and mailgen development in all variants
DEV_CERTBUND_RULES=./intelmq/rules
DEV_CERTBUND_TEMPLATES=./mailgen/templates
DEV_CERTBUND_FORMATS=./mailgen/formats
```

In the third section the repository revisions for the default scenario are configured.
```
# Revisions for source variant
SOURCE_INTELMQ_REVISION=develop
SOURCE_INTELMQ_PYPI_VERSION=3.3.0
SOURCE_INTELMQ_API_REVISION=develop
SOURCE_INTELMQ_MANAGER_REVISION=develop
SOURCE_FODY_REVISION=master
SOURCE_FODY_BACKEND_REVISION=master
SOURCE_WEBINPUT_CSV_REVISION=master
SOURCE_WEBINPUT_CSV_BACKEND_REVISION=master
SOURCE_INTELMQ_CERTBUND_CONTACT_REVISION=master
SOURCE_INTELMQ_MAILGEN_REVISION=master
```

In the fourth section, the [IntelMQ unstable repository](https://software.opensuse.org/download.html?project=home%3Asebix%3Aintelmq%3Aunstable&package=intelmq) can be optionally activated (in addition to the default stable repository) to test pre-releases of IntelMQ:
```
# Set to true for using the IntelMQ unstable repository
INTELMQ_UNSTABLE_REPOSITORY=false
```

The last section defines a switch to integrate a basic but complete CERT-BUND bot and mailgen configuration that applies to all scenarios at build time.
```
# deactivated:
USE_CERTBUND=false
# Switch on the integration of certbund bot and mailgen configuration:
USE_CERTBUND=true
```

### Scenario 1: From source (default)

This requires local copies of all programs.
Correct `*_SRC` settings in the `.env` are required for this scenario to work (see configuration section above).

```
docker compose build --no-cache
```

Creates the Images using the dockerfiles.
The `--no-cache` flags prevents docker from using old intermediate images.

```
docker compose up
```

Creates and starts the containers.
Add `-d` to run in background.


### Scenario 2: Development ('dev')

Using the docker containers for development requires a local checkout of fody and fody-backend. Mounting them as volume is specified in the `docker-compose.dev.yml` and the path to the source code is defined in the `.env` file.

```
docker compose -f docker-compose.yml -f docker-compose.dev.yml build --no-cache
```

Creates the Images using the dockerfiles.
The `--no-cache` flags prevents docker from using old intermediate images.

```
docker compose -f docker-compose.yml -f docker-compose.dev.yml up
```

Creates and starts the containers.
Add `-d` to run in background.

The Fody and Webinput-CSV (frontend) containers start with yarn in development mode. Changes in the code automatically trigger a refresh in the browser. Only if dependencies change a login to the container is required to restart the yarn dev server:

```
docker exec -ti intelmq-fody-spa /bin/bash
    $ kill `pidof node`
    $ yarn
    $ yarn run dev 2>&1 &
```

Do not kill the `tail` process. It keeps the container alive when killing node processes.

### Scenario 3: Local packages ('pkg')

Building images and containers with self built intelmq packages (intelmq-certbund-contact, intemq-fody-backend, intemq-fody), it assumed that the packages are available under `./packages`. Upstream packages from sebix and Intevation repository are used as backup for all packages not existing locally.

```
mkdir packages
cp $PATH_TO_PKGS/* packages/
docker compose -f docker-compose.yml -f docker-compose.pkg.yml build
docker compose -f docker-compose.yml -f docker-compose.pkg.yml up
```

### Scenario 4: Repository packages ('full-pkg')

Building a setup of all the applications using the package repositories can be done with

```
docker compose -f docker-compose.yml -f docker-compose.pkg.yml -f docker-compose.full-pkg.yml build
docker compose -f docker-compose.yml -f docker-compose.pkg.yml -f docker-compose.full-pkg.yml up
```

The latest packages are used, no versions can be specified in this scenario.

### General

```
docker compose down
```

Stops and removes the containers.

```
docker compose stop
```

Stops the containers.

```
docker compose images
```

Lists all images used for the services.

```
docker rmi intelmq-base intelmq-database intelmq-database intelmq-fody-backend intelmq-fody-spa
```

Removes the images.

### The containers

```
docker compose start
```

Starts already existing containers


### Using the applications

IntelMQ-Manager, Fody and Webinput-CSV need credentials to login.
The default user is `admin` with the password `secret`. For more users
login to the docker container running ` intelmq-api`,
`intelmq-fody-backend` or `intelmq-webinput-csv-backend` and follow
the instructions in the documentation  for [IntelMQ-Manager](https://intelmq.readthedocs.io/en/maintenance/user/intelmq-api.html#id6),
[Fody](https://github.com/Intevation/intelmq-fody-backend#authentication) and
[Webinput-csv](https://intevation.github.io/intelmq-webinput-csv/installation.html).

#### ContactDB

Using the contactdb depends on data that can change daily. The directory name contains the current date so rebuilding the container with an image on an other date than the image was build leaves the database empty.

Rebuild the image with no cache to get an up to date database.

Starting the setup with a fresh data import for the contactdb will take some time so please be patient.

#### Mailgen

Run mailgen in the mailgen container:
```bash
docker exec -ti mailgen bash
intelmqcbmail
```
The default entrypoint calls intelmqcbmail every five minutes.

Read the mails by entering the dsmtpd container and run:
```bash
docker exec -ti intelmq-dsmtpd bash
mutt -f /opt/mails/incoming
```

#### IntelMQ
To use `intelmqctl` you need to set environment variables, which are normally set by `docker compose`:
```bash
docker exec --env-file=.env -ti --network intelmq-cb-mailgen-docker_intelmq intelmq bash
```

#### Database

To enter the database, use
```bash
docker exec -ti intelmq-database psql -h localhost contactdb
docker exec -ti intelmq-database psql -h localhost eventdb
```

## Tests

To run the tests, call `testall.sh`:
```
./testall.sh
```
Please note that this clears
- all data in the database tables `events` and `directives`
- all data in the redis database

Or execute the tests per container by executing the single commands from this file.

You can activate the debug mode (`set -x`) by using `DEBUG=1`.
To skip the IntelMQ unittests (which take a while to complete, set `INTELMQ_SKIP_UNITTESTS=1` in `.env`.

## webinput-csv-intelmq-mailgen

The container `webinput-csv-intelmq-mailgen` is special and not started by default. Only available as dev-version.
It combines intelmq, intelmq-api, intelmq-manager, intelmq-certbund-contact, intelmq-mailgen and intelmq-webinput-csv in one container.
Everything except fody.

Start:
```bash
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.dev.yml up --build webinput-csv-intelmq-mailgen
```
