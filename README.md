# Intelmq-fody development environment

Use dockerfiles and/or compose file to build up a complete development
enviroment for intelmq and fody.

### FOR DEVELOPMENT ONLY! CONTAINS INSECURE PLAINTEXT PASSWORDS!

## Usage

### Build and startup
```docker-compose up --build```

Creates the Images and starts the containers.
Add ```-d``` to run in background.

```docker-compose start```

Starts already existing containers

```docker-compose down```

Stops and removes the containers.

```docker-compose stop```

Stops the containers.

### Using the containers

The IntelMQ-Manager is listening on port 1337 and the Fody frontend is available on port 1380 per default.

IntelMQ-Manager needs credentials to login.
The default user is ```admin``` with the password ```secret```. For more users login to the docker container named ``` intelmq-base``` and follow the intstructions in the [documentation](https://intelmq.readthedocs.io/en/maintenance/user/intelmq-api.html#id6)
## ContactDB

Using the contactdb depends on data that can change daily. The directory name contains the current date so rebuilding the container with an image on an other date than the image was build leaves the database empty.

Rebuild the image to get an up to date database.

Starting the setup with a fresh data import for the contactdb will take some time so please be patient.

## TODO

Documentation how to mount development folders and refresh containers.
