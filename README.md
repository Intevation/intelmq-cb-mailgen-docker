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

## TODO

Documentation how to mount development folders and refresh containers.