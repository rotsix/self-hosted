# Self-hosted

## Requirements

Needed packages:

On host:

- `ansible`

On target:

- `python3` (ansible requirement)
- a sudo-able user

The architecture consists yet of the following components:

- a Nginx+TLS reverse-proxy, it handles subdomains and routing to dedicated container
- a personal homepage, managed by a Jekyll container (`domain.tld`)
- a NextCloud instance (`cloud.domain.tld`)
- a git viewer, Klaus (`git.domain.tld`)

## Configuration

All the congurations are contained in `config.yml`.
Edit the file, then run the project.

The git repositories are at `/home/git` by default, this allowing to clone the repositories this way:

```
git clone git@domain.tld:repo.git
```

Or, using Klaus URL:

```
git clone https://git.domain.tld/repo.git
```

The web files are at `/tmp/www` by default.
In my case, they are located at `/home/git/.website-clone` as the sources are in another repository.
Using the default value without an `index.html` in the default directory may result in an error (likely 404).

## Running

To get this project up and running, get the sources:

```sh
git clone https://git.franzi.fr/self-hosted
```

This project is managed by ansible.
To deploy the architecture to a server, run the following command:

```sh
# trailing comma is mandatory   v
$ ansible-playbook -i domain.tld, -u user playbook.yml
```

By default, all the docker volumes are located in `/mnt`.
You may want to backup this directory.
