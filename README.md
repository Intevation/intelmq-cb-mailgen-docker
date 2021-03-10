# Intelmq-fody development environment

Use dockerfiles and/or compose file to build up a complete development
enviroment for intelmq and fody.

### FOR DEVELOPMENT ONLY! CONTAINS INSECURE PLAINTEXT PASSWORDS!

## Usage

```docker-compose up --build```

Creates the Images and starts the containers.
Add ```-d``` to run in background.

```docker-compose start```

Starts already existing containers

```docker-compose down```

Stops and removes the containers.

```docker-compose stop```

Stops the containers.

## ContactDB

Using the contactdb depends on data that can change daily. The directory name contains the current date so rebuilding the container with an image on an other date than the image was build leaves the databse empty.

Rebuild the image to get an up to date database.

Starting the setup with a fresh data import for the contactdb will take some time so please be patient.

## TODO

Documentation how to mount development folders and refresh containers.