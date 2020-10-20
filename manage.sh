#!/bin/bash
set -euo pipefail

source db.env
source config.env

DC="docker-compose --env-file ./config.env"


log () { echo -e "\e[1m## $1\e[0m"; }
log_n () { echo -en "\e[1m## $1\e[0m"; }

usage () {
	echo "usage: ./manage.sh <cmd>"
	echo "    db <cmd>"
	echo "       add_user <user>"
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
		case $ans in
			y|Y|yes|+)
				return 0
				;;
			n|N|no|-)
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
	docker exec -it self-hosted_db_1 createuser \
		-U "$POSTGRES_USER" \
		-P \
		"$1" || log "can't create user '$1'"

	log "'$POSTGRES_USER' is creating db '$1':"
	docker exec -it self-hosted_db_1 createdb \
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
		echo "$HOSTNAME" | sudo tee /etc/hostname
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
		if grep "^git" /etc/passwd; then
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

	sudo chmod 755 /home/git
	sudo cp -r ./git-shell-commands /home/git
	sudo chown -R git:git /home/git
}

init () {
	# in case of
	$DC up -d db

	log "\e[94mcreate Nextcloud db user"
	init_nextcloud

	log "\e[94mset hostname"
	init_hostname

	log "\e[94mset firewall"
	init_firewall

	log "\e[94mcreate git user"
	init_git

	# and stop
	$DC stop db
}

# https://stackoverflow.com/a/3601734
test -z "${1+x}" && usage && exit

case "$1" in
	init)
		init
		;;

	db|database)
		test -z "${2+x}" && usage && exit
		case "${2}" in
			add_user|adduser)
				test -z "${3+x}" && usage && exit
				db_adduser "$3"
				;;
			*)
				echo "command not found"
				exit 1
				;;
		esac
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
