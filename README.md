# Intelmq-fody development environment

Use dockerfiles and/or compose file to build up a complete development
enviroment for intelmq and fody.

### FOR DEVELOPMENT ONLY! CONTAINS INSECURE PLAINTEXT PASSWORDS!

## Contents

- [Introduction](#Introduction)
- [Building Packages](#building-packages)
- [Setup Scenarios](#setup-scenarios)
    - [Configuration env](#configuration-env)
    - [Scenario 1](#scenario-1-default)
    - [Scenario 2](#scenario-2)
    - [Scenario 3](#scenario-3)
    - [Scenario 4](#scenario-4)
    - [General](#General)
    - [The Containers](#the-containers)
    - [Using the applications](#using-the-applications)
- [ContactDB](#contactdb)

## Introduction

This repository contains docker environments for building packages and using a full intelmq setup with different scenarios.

The following scenarios are supported:
1. Test-Setup with services build from source with a given revision (default is master)
1. Development-Setup with mounted source code for easy editing
1. Test-Setup with services build from package (file system)
1. Test-Setup with services build from package (repository)


## Building packages

Currently the build process supports Ubuntu focal only and builds the following packages:

* intelmq-fody
* intelmq-fody-backend
* intelmq-mailgen
* intelmq-certbund-contact
* intelmq-webinput-csv
* intelmq-webinput-csv-backend

To start the build process use ```./pkg/build-packages.sh```.
The script takes a couple of parameters given as enviroment variables.

* IMQ_BUILD_PACKAGES - List of packages to build
* IMQ_BUILD_RELEASE - Switch to build a release package (values are "yes" or "no")
* IMQ_BUILD_DIR - Destination directory for the resulting logs and packages (will be prefixed with current $HOME)

## Setup Scenarios

On the first startup, the two containers intelmq-contactdb and intelmq-fody-backend seem to hang. The reason is that the data import for the contactdb takes some time and the fody backend waits for the import to finish.

Ports on the host machine for the applications and APIs:

* intelmq-manager: 1380
* intelmq-api: 1381 (not in all scenarios)
* intelmq-fody: 1382
* intelmq-fody-backend: 1340 (not in all scenarios)
* intelmq-webinput-csv: 1383
* intelmq-webinput-csv-backend: 1341 (not in all scenarios)

### Configuration env

The complete stack is mostly configured via the .env-file and has four 'sections'.

The first section configures the paths to develpment directories contianing the source of the components 'fody', 'fody-backend', 'webinput-csv' and 'webinput-csv-backend'.
```
# Mounted source directories in dev variant
DEV_FODY_SRC=../intelmq-fody
DEV_FODY_BACKEND_SRC=../intelmq-fody-backend
DEV_WEBINPUT_CSV_SRC=../intelmq-webinput-csv/client
DEV_WEBINPUT_CSV_BACKEND_SRC=../intelmq-webinput-csv
```

The second section configures the paths to rules, templates and formats of CERT-BUND bots and mailgen. These paths are mounted in all scenarios. The content can be changed during runtime, but remember to restart bots on change.
```
# Mounted directories for rule and mailgen development in all variants
DEV_CERTBUND_RULES=./intelmq/rules
DEV_CERTBUND_TEMPLATES=./intelmq/templates
DEV_CERTBUND_FORMATS=./intelmq/formats
```

In the third section the repository revisions for the default scenario are configured.
```
# Revisions for source variant
SOURCE_INTELMQ_REVISION=2.3.3
SOURCE_INTELMQ_API_REVISION=2.3.1
SOURCE_INTELMQ_MANAGER_REVISION=2.3.1
SOURCE_FODY_REVISION=master
SOURCE_FODY_BACKEND_REVISION=master
SOURCE_WEBINPUT_CSV_REVISION=master
SOURCE_WEBINPUT_CSV_BACKEND_REVISION=master
```

The last section defines a switch to integrate a basic but complete CERT-BUND bot and mailgen configuration that applies to all scenarios at build time.
```
# Switch to integrate certbund bot and mailgen configuration
USE_CERTBUND=false
```

### Scenario 1 (default)

```docker compose build --no-cache```

Creates the Images using the dockerfiles.
The ```--no-cache``` flags prevents docker from using old intermediate images.

``` docker compose up```

Creates and starts the containers.
Add ```-d``` to run in background.


### Scenario 2

Using the docker containers for development requires a local checkout of fody and fody-backend. Mounting them as volume is specified in the ```docker-compose.dev.yml``` and the path to the source code is defined in the ```.env``` file.

```docker compose -f docker-compose.yml -f docker-compose.dev.yml build --no-cache```

Creates the Images using the dockerfiles.
The ```--no-cache``` flags prevents docker from using old intermediate images.

``` docker compose -f docker-compose.yml -f docker-compose.dev.yml up```

Creates and starts the containers.
Add ```-d``` to run in background.

The Fody and Webinput-CSV (frontend) containers start with yarn in development mode. Changes in the code automaticaly trigger a refresh in the browser. Only if dependencies change a login to the container is required to restart the yarn dev server:

```
docker exec -ti intelmq-fody-spa /bin/bash
    $ kill `pidof node`
    $ yarn
    $ yarn run dev 2>&1 &
```

Do not kill the ```tail``` process. It keeps the container alive when killing node processes.

### Scenario 3

Building images and containers with self built intelmq packages (intelmq-certbund-contact, intemq-fody-backend, intemq-fody), it assumed that the packages are available under ```./packages```.

```
mkdir packages
cp $PATH_TO_PKGS/* packages/
docker compose -f docker-compose.yml -f docker-compose.pkg.yml build
docker compose -f docker-compose.yml -f docker-compose.pkg.yml up
```

### Scenario 4

Building a setup of all the applications using the package repositories can be done with

```
docker compose -f docker-compose.yml -f docker-compose.full-pkg.yml build
docker compose -f docker-compose.yml -f docker-compose.full-pkg.yml up
```

### General

```docker-compose down```

Stops and removes the containers.

```docker-compose stop```

Stops the containers.

```docker-compose images```

Lists all images used for the services.

``` docker rmi intelmq-base intelmq-contactdb intelmq-eventdb intelmq-fody-backend intelmq-fody-spa```

Removes the images.

### The containers

```docker-compose start```

Starts already existing containers


### Using the applications

IntelMQ-Manager, Fody and Webinput-CSV need credentials to login.
The default user is ```admin``` with the password ```secret```. For more users login to the docker container named ``` intelmq-base``` or ```intelmq-fody-backend``` and follow the intstructions in the [documentation](https://intelmq. readthedocs.io/en/maintenance/user/intelmq-api.html#id6) for IntelMQ-Manager and [TODO]() for Fody.
## ContactDB

Using the contactdb depends on data that can change daily. The directory name contains the current date so rebuilding the container with an image on an other date than the image was build leaves the database empty.

Rebuild the image with no cache to get an up to date database.

Starting the setup with a fresh data import for the contactdb will take some time so please be patient.
