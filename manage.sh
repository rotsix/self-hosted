#!/bin/bash
set -e

source db.env

db_adduser () {
	echo "'$POSTGRES_USER' is creating user '$1':"
	docker exec -it self-hosted_db_1 createuser \
		-U $POSTGRES_USER -W \
		-P \
		"$1"

	echo "'$POSTGRES_USER' is creating db '$1':"
	docker exec -it self-hosted_db_1 createdb \
		-U $POSTGRES_USER -W \
		-O "$1" \
		"$1"
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

case "$1" in
	init)
		docker-compose up -d db
		db_adduser "nextcloud"
		docker-compose stop db
		;;
	db|database)
		case "$2" in
			add_user|adduser)
				db_adduser "$3"
				;;
			*)
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
