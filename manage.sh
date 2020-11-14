#!/bin/bash
set -euo pipefail

source db.env
source config.env

DC="docker-compose --env-file ./config.env"

bold="\e[1m"
blue="\e[34m"
default="\e[39m"
reset="\e[0m"
log () { echo -e "$bold$blue::$default $1$reset"; }
log_n () { echo -en "$bold$blue::$default $1$reset"; }

usage () {
	echo "usage: ./manage.sh <cmd>"
	echo "    init"
	echo "    test"
	echo "    mrproper /!\\"
	echo
	echo "all other commands are passed directly to docker-compose"
}

ask () {
	if [ -n "$FORCE" ]; then
		return 0
	fi

	log_n "$1 [yN] "
	while IFS= read -r ans; do
		case ${ans,,} in
			y|yes|+)
				return 0
				;;
			n|no|-)
				return 1
				;;
			*)
				log "not a valid choise, aborting"
				return 1
				;;
		esac
		log_n "$1 "
	done
}

db_adduser () {
	log "'$POSTGRES_USER' is creating user '$1':"
	docker exec -it db createuser \
		-U "$POSTGRES_USER" \
		-P \
		"$1" || log "can't create user '$1'"

	log "'$POSTGRES_USER' is creating db '$1':"
	docker exec -it db createdb \
		-U "$POSTGRES_USER" \
		-O "$1" \
		"$1" || log "can't create db '$1'"
}

init_nextcloud () {
	db_adduser "nextcloud"
}

init_hostname () {
	if [ -z "$HOSTNAME" ]; then
		log_n "hostname: "
		read -r HOSTNAME
	fi
	if [ -n  "$HOSTNAME" ]; then
		if [ "$HOSTNAME" != "localhost" ]; then
			sudo hostname "$HOSTNAME"
			echo "$HOSTNAME" | sudo tee /etc/hostname
		fi
	else
		log "no hostname provided"
	fi
}

init_firewall () {
	sudo systemctl enable --now ufw
	if [ -n "$FORCE" ]; then
		sudo ufw --force reset
	else
		sudo ufw reset
	fi
	sudo ufw enable
	sudo ufw default deny
	sudo ufw limit ssh
	sudo ufw allow http
	sudo ufw allow https
}

init_git () {
	if ! grep "git-shell" /etc/shells; then
		which git-shell | sudo tee -a /etc/shells
	fi
	if [ -d /home/git ]; then
		log "user 'git' already exist"
	else
		log "not home found for 'git'"
		if grep "^git:" /etc/passwd; then
			if ask "overwrite 'git' user?" ; then
				sudo userdel -r git
			else
				log "can't create user 'git'"
				return
			fi
		fi
		sudo useradd --create-home --skel /dev/null \
			--home-dir /home/git --shell /usr/bin/git-shell \
			git
	fi

	cat << EOF | sudo bash
	rm -rf /home/git/git-shell-commands || true
	cp -rf ./git-shell-commands /home/git
	chown -R git:git /home/git
EOF
	log "/!\\ add SSH key to '/home/git/.ssh/authorized_keys'"
}

init () {
	prefix="\b$blue··$default "

	# in case of
	$DC up -d db

	log "${prefix}init nextcloud"
	init_nextcloud

	log "${prefix}init hostname"
	init_hostname

	log "${prefix}init firewall"
	init_firewall

	log "${prefix}init git"
	init_git

	# and stop
	$DC stop db
}

run_tests () {
	echo "all went fine"
}

# https://stackoverflow.com/a/3601734
test -z "${1+x}" && usage && exit

case "$1" in
	init)
		init
		;;

	test)
		run_tests
		;;

	mrproper)
		$DC down
		sudo rm -rf ./volumes
		docker volume prune
		sudo rm -rf "$WEB_FILES/_site"
		sudo rm -rf "$WEB_FILES/.jekyll-cache"
		;;

	*)
		$DC "$@"
		exit 1
		;;
esac
