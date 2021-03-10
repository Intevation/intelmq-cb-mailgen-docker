# Files for the contactdb container

Place all contactdb related files here.

# init folder

Contains the init script for the contact db setup.
This folder will be mounted to the entrypoint folder. All scripts and sql files
will be executed on container startup.

# initdb.sql

Schema definition for the eventdb. Used in the init-sh script.
Do not place this script in the init folder. It has to be imported during the
setup process, not standalone.
