# Self-hosted

## Installation

Needed packages:

- `docker`/`docker-compose`: obvious
- `ufw`: firewall
- `git`: obvious again

The architecture consists yet of the following components:

- a Nginx+TLS reverse-proxy, it handles subdomains and routing to dedicated container
- a personal homepage, managed by a Jekyll container (`domain.tld`)
- a NextCloud instance (`cloud.domain.tld`)
- a git viewer, Klaus (`git.domain.tld`)

To get this project up and running, get the sources:

```sh
git clone https://git.franzi.fr/self-hosted
```

## Initialization

First, some settings have to be setup before launching the services.
By example, Nextcloud relies on a database.

An all-in-one script is available (`./manage.sh`).
To initialize the architecture, first edit the `env` files.
Each folder may contain one, so look closely (you also can use `find . -name "*.env"`).

Then, run the script:

```sh
./manage.sh init
```

This command can be run before each run, it **won't** erase any existing data.

> Note: after the very first init, a reboot is required to update the hostname (`/etc/hostname`).

By default, all the docker volumes are located in `./volumes`.
You may want to backup this directory.

## Running

Once initialized, simply launch the services:

```sh
./manage.sh up
# or in background
./manage.sh up -d
```

All commands to `manage.sh` will go directly to `docker-compose`, it just pass the `-e config.env` flag.

## Update

```sh
./manage.sh down
git pull
./manage.sh up -d
```
