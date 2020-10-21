# Self-hosted

## Installation

Needed packages:

- `docker`/`docker-compose`: obvious
- `ufw`: firewall
- `git`: obvious again

The architecture consists yet of the following components:

- a Nginx+TLS reverse-proxy, it handles subdomains and routing to dedicated container
- a personal homepage, managed by a Jekyll container (`domain.tld`>)
- a NextCloud instance (`cloud.domain.tld`)
- a git viewer, Klaus (`git.domain.tld`)

To get this project up and running, get the sources:

```sh
git clone https://github.com/rotsix/self-hosted
```

## Initialization

First, some settings have to be setup before launching the services.
By example, NextCloud needs a dedicated database.

A all-in-one script is available (`./manage.sh`).
To initialize the architecture, first edit the `env` files.
Each folder may contain one, so take a close look.

Then, run the script:

```sh
./manage.sh init
```

This command can be launched before each run, it **won't** erase any existing data.

> Note: after the very first init, a reboot is required to update the hostname (`/etc/hostname`).

By default, all the docker volumes are located in `./volumes`.
You may want to backup this directory.

## Running

Once initialized, simply launch the services:

```sh
./manage.sh up
# or in background
./manage.sh -d up
```

All commands passed to `manage.sh` will go directly to `docker`, it just add the `-e config.env` flag.

## Update

```sh
./manage.sh down
git pull
./manage.sh init
./manage.sh -d up
```
