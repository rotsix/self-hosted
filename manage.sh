#!/bin/bash
set -euo pipefail

source db.env

db_adduser () {
	echo "## '$POSTGRES_USER' is creating user '$1':"
	docker exec -it self-hosted_db_1 createuser \
		-U "$POSTGRES_USER" -W \
		-P \
		"$1" || echo "can't create user '$1'"

	echo "## '$POSTGRES_USER' is creating db '$1':"
	docker exec -it self-hosted_db_1 createdb \
		-U "$POSTGRES_USER" -W \
		-O "$1" \
		"$1" || echo "can't create db '$1'"
}

usage () {
	echo "usage: ./manage.sh <cmd>"
	echo "    db <cmd>"
	echo "        add_user <user>"
	echo "    mrproper /!\\"
	echo
	echo "all commands are passed directly to docker-compose"
}

test -z "$1" && usage && exit

init () {
	echo "### create Nextcloud db user"
	docker-compose up -d db
	db_adduser "nextcloud"
	docker-compose stop db

	echo "### set webmaster email"
	echo -n "email (leave empty for 'root@\$HOST'): "
	read -r email
	if [[ -n "$email" ]]; then
		sed -i "s/root@localhost/$email/g" docker-compose.yml
	else
		echo "no email provided"
	fi

	echo "### set hostname"
	echo -n "hostname (leave empty for 'localhost'): "
	read -r host
	if [[ -n  "$host" ]]; then
		sed -i "s/localhost/$host/g" docker-compose.yml
	else
		echo "no hostname provided"
	fi

	echo "### set firewall"
	sudo systemctl enable --now ufw
	sudo ufw reset
	sudo ufw enable
	sudo ufw default deny
	sudo ufw limit ssh
	sudo ufw allow http
	sudo ufw allow https
}

case "$1" in
	init)
		init
		;;

	db|database)
		case "$2" in
			add_user|adduser)
				db_adduser "$3"
				;;
			*)
				echo "command not found"
				exit 1
				;;
		esac
		;;

	mrproper)
		docker-compose down
		sudo rm -rf ./volumes/
		docker volume prune
		;;

	*)
		docker-compose "$@"
		exit 1
		;;
esac
