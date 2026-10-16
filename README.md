# IntelMQ development environment

Use Docker-Compose to build up a complete development and test
environment for IntelMQ, Manager, fody, mailgen and webinput

### FOR DEVELOPMENT ONLY! CONTAINS INSECURE PLAINTEXT PASSWORDS!

## Contents

- [Introduction](#Introduction)
- [Building Packages](#building-packages)
- [Configuration env](#configuration-env)
- [Setup Scenarios](#setup-scenarios)
    - [Scenario 1 ("Source")](#scenario-1-from-source-from-source)
    - [Scenario 2 ("Development")](#scenario-2-development-dev)
    - [Scenario 3 ("Development")](#scenario-3-webinputcsv-development-dev-csv)
    - [Scenario 4 ("packages")](#scenario-4-local-packages-pkg)
    - [Scenario 5 ("full packages")](#scenario-5-repository-packages-full-pkg)
    - [General](#General)
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

Ports on the host machine for the applications and APIs:

* intelmq-manager: 1380 (path `/intelmq-manager`)
* intelmq-api: 1381 (not in all scenarios)
* intelmq-fody: 1382
* intelmq-fody-backend: 1340 (not in all scenarios)
* intelmq-webinput-csv: 1383
* intelmq-webinput-csv-backend: 1341 (not in all scenarios)

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
* IMQ_BUILD_VERSION - git refspec of IntelMQ to build. Default: develop
* IMQ_BUILD_API_VERSION - git refspec of IntelMQ API to build. Default: develop
* IMQ_BUILD_MANAGER_VERSION - git refspec of IntelMQ Manager to build. Default: develop
* IMQ_BUILD_FODY_VERSION - git refspec of IntelMQ Fody to build. Default: master
* IMQ_BUILD_FODY_BACKEND_VERSION - git refspec of IntelMQ Fody Backend to build. Default: master
* IMQ_BUILD_MAILGEN_VERSION - git refspec of IntelMQ Mailgen to build. Default: master
* IMQ_BUILD_CERTBUND_CONTACT_VERSION - git refspec of IntelMQ CERTBund Contact to build. Default: master
* IMQ_BUILD_WEBINPUT_CSV_VERSION - git refspec of IntelMQ Webinput CSV to build. Default: master

## Configuration env

The complete stack is mostly configured via the .env-file and has four 'sections'.

The first section configures the paths to development directories containing the source code of required components, which you will need to download in addition to this repository: [`intelmq`](https://github.com/certtools/intelmq), [`intelmq-api`](https://github.com/certtools/intelmq-api), [`intelmq-manager`](https://github.com/certtools/intelmq-manager), [`intelmq-fody`](https://github.com/Intevation/intelmq-fody), [`intelmq-fody-backend`](https://github.com/Intevation/intelmq-fody-backend), [`intelmq-webinput-csv`](https://github.com/Intevation/intelmq-webinput-csv), [`intelmq-certbund-contact`](https://github.com/Intevation/intelmq-certbund-contact), [`intelmq-mailgen`](https://github.com/Intevation/intelmq-mailgen)
```sh
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
```sh
# Mounted directories for rule and mailgen development in all variants
DEV_CERTBUND_RULES=./intelmq/rules
DEV_CERTBUND_TEMPLATES=./mailgen/templates
DEV_CERTBUND_FORMATS=./mailgen/formats
```

In the third section the repository revisions for the default scenario are configured.
```sh
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
```sh
# Set to true for using the IntelMQ unstable repository
INTELMQ_UNSTABLE_REPOSITORY=false
```

The last section defines a switch to integrate a basic but complete CERT-BUND bot and mailgen configuration that applies to all scenarios at build time.
```sh
# deactivated:
USE_CERTBUND=false
# Switch on the integration of certbund bot and mailgen configuration:
USE_CERTBUND=true
```

## Setup Scenarios

The first startup of the intelmq-database container needs a few minutes to import the data for the contactdb. After that, even if you `docker compose down`, it will be faster because the data is persisted in a named volume. See [below](#contactdb).

The different scenarios require different combinations of Docker Compse files. `docker-*.sh` utility scripts are provided that each amount to `docker compose -f ... "$@"`, i.e., they run `docker compose` with the appropriate Compose files and the arguments you provide. So e.g. `./docker-from-source.sh up --build` performs `docker compose up --build` with the Compose files for Scenario 1 (running from source).

### Scenario 1: From source (`from-source`)

This requires local copies of all programs.
Correct `*_SRC` settings in the `.env` are required for this scenario to work (see configuration section above).

```sh
./docker-from-source.sh build --no-cache
```

Creates the Images using the dockerfiles.
The `--no-cache` flags prevents docker from using old intermediate images.

```sh
./docker-from-source.sh compose up
```

Creates and starts the containers.
Add `-d` to run in background.


### Scenario 2: Development (`dev`)

Using the docker containers for development requires a local checkout of fody and fody-backend. Mounting them as volume is specified in the `docker-compose.dev.yml` and the path to the source code is defined in the `.env` file.

```sh
./docker-dev.sh build --no-cache
```

Creates the Images using the dockerfiles.
The `--no-cache` flags prevents docker from using old intermediate images.

```sh
./docker-dev.sh up
```

Creates and starts the containers.
Add `-d` to run in background.

The Fody and Webinput-CSV (frontend) containers start with yarn in development mode. Changes in the code automatically trigger a refresh in the browser. Only if dependencies change a login to the container is required to restart the yarn dev server:

```sh
docker exec -ti intelmq-fody-spa /bin/bash
    kill `pidof node`
    yarn
    yarn run dev 2>&1 &
```

Do not kill the `tail` process. It keeps the container alive when killing node processes.

### Scenario 3: WebinputCSV development (`dev-csv`)

This combines intelmq, intelmq-api, intelmq-manager, intelmq-certbund-contact, intelmq-mailgen and intelmq-webinput-csv into one container (everything except Fody). This is apparently required for WebinputCSV to work properly.

```sh
./docker-dev-csv.sh up --build
```

### Scenario 4: Local packages (`pkg`)

Building images and containers with self built intelmq packages (intelmq-certbund-contact, intemq-fody-backend, intemq-fody), it assumed that the packages are available under `./packages`. Upstream packages from sebix and Intevation repository are used as backup for all packages not existing locally.

```sh
mkdir packages
cp $PATH_TO_PKGS/* packages/
./docker-pkg.sh build
./docker-pkg.sh up
```

### Scenario 5: Repository packages (`full-pkg`)

Building a setup of all the applications using the package repositories can be done with

```sh
./docker-full-pkg.sh build
./docker-full-pkg.sh up
```

The latest packages are used, no versions can be specified in this scenario.

### General

- When running in foreground (without `-d`), Ctrl + C stops the containers.
- `./docker-*.sh down` removes the containers. When running with `-d`, also stops them beforehand. If you add `-v`, volumes (i.e., the database contents) will also be removed.
- `./docker-*.sh stop` can be used to stop the containers when they were started with `-d`.
- `./docker-*.sh start` starts them again (unlike `up`, does not recreate them even if configuration changed).
- `./docker-*.sh images` lists all images used for the services.

To remove all the images, you can do:

```sh
docker image remove \
    intelmq-database intelmq-dsmtpd \
    intelmq intelmq-fody intelmq-fody-backend intelmq-mailgen intelmq-webinput-csv-spa intelmq-webinput-csv-backend \
    intelmq-dev intelmq-fody-dev intelmq-fody-backend-dev intelmq-database-dev intelmq-mailgen-dev intelmq-webinput-csv-dev intelmq-webinput-csv-backend-dev \
    intelmq-pkg intelmq-fody-pkg intelmq-fody-backend-pkg intelmq-mailgen-pkg intelmq-webinput-csv-pkg intelmq-webinput-csv-backend-pkg \
    intelmq-full-pkg intelmq-fody-full-pkg intelmq-fody-backend-full-pkg intelmq-database-full-pkg intelmq-mailgen-full-pkg intelmq-webinput-csv-full-pkg intelmq-fody-backend-full-pkg \
    intelmq-webinput-csv-backend-mailgen-dev
```

But you could also just `docker image prune -a` to remove **all** local images (not just IntelMQ ones). (See also: `docker volume prune -a`)

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

Rebuild the image with no cache to get an up to date database. (← This seems out-of-date; `docker-*.sh down -v` should do it.)

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
docker exec --env-file=.env -ti intelmq bash
```

#### Database

To enter the database, use
```bash
docker exec -ti intelmq-database psql -h localhost contactdb
docker exec -ti intelmq-database psql -h localhost eventdb
```

## Tests

To run the tests, call `testall.sh`:
```sh
./testall.sh
```
Please note that this clears
- all data in the database tables `events` and `directives`
- all data in the redis database

Or execute the tests per container by executing the single commands from this file.

You can activate the debug mode (`set -x`) by using `DEBUG=1`.
To skip the IntelMQ unittests (which take a while to complete, set `INTELMQ_SKIP_UNITTESTS=1` in `.env`.
