# Intelmq-fody development environment

Use dockerfiles and/or compose file to build up a complete development
enviroment for intelmq and fody.

### FOR DEVELOPMENT ONLY! CONTAINS INSECURE PLAINTEXT PASSWORDS!

## Contents

- [Introduction](#Introduction)
- [Usage](#Usage)
    - [Scenario 1](#scenario-1-default)
    - [Scenario 2](#scenario-2)
    - [General](#General)
## Introduction

The docker (-compose) environment can be used for four differnet scenarios:

1. Test-Setup with services build from source with a given revision (default is master)
1. Development-Setup with mounted source code for easy editing
1. Test-Setup with services build from package (file system)
1. Test-Setup with services build from package (repository)

## Usage

On the first startup, the two containers intelmq-contactdb and intelmq-fody-backend seem to hang. The reason is that the data import for the contactdb takes some time and the fody backend waits forthe import to finish.

### Scenario 1 (default)

```docker-compose build --no-cache```

Creates the Images using the dockerfiles.
The ```--no-cache``` flags prevents docker from using old intermediate images.

``` docker-compose up```

Creates and starts the containers.
Add ```-d``` to run in background.

### Scenario 2

Using the docker containers for development requires a local checkout of fody and fody-backend. Mounting them as volume is specified in the ```docker-compose.dev.yml``` and the path to the source code is defined in the ```.env``` file.

```docker-compose -f docker-compose.yml -f docker-compose.dev.yml build --no-cache```

Creates the Images using the dockerfiles.
The ```--no-cache``` flags prevents docker from using old intermediate images.

``` docker-compose -f docker-compose.yml -f docker-compose.dev.yml up```

Creates and starts the containers.
Add ```-d``` to run in background.

The Fody (frontend) container starts with yarn in development mode. Changes in the code automaccaly trigger a refresh in the browser. Only if dependensies change a login to the container is required to restart the yarn dev server:

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

The IntelMQ-Manager is listening on port 1337 and the Fody frontend is available on port 1380 per default.

IntelMQ-Manager and Fody need credentials to login.
The default user is ```admin``` with the password ```secret```. For more users login to the docker container named ``` intelmq-base``` or ```intelmq-fody-backend``` and follow the intstructions in the [documentation](https://intelmq. readthedocs.io/en/maintenance/user/intelmq-api.html#id6) for IntelMQ-Manager and [TODO]() for Fody.
## ContactDB

Using the contactdb depends on data that can change daily. The directory name contains the current date so rebuilding the container with an image on an other date than the image was build leaves the databse empty.

Rebuild the image with no cache to get an up to date database.

Starting the setup with a fresh data import for the contactdb will take some time so please be patient.
