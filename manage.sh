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
	echo "       add_user <user>"
	echo "    mrproper /!\\"
	echo
	echo "all other commands are passed directly to docker-compose"
}

init_nextcloud () {
	db_adduser "nextcloud"
}

init_webmaster_email () {
	echo -n "email (leave empty for 'root@\$HOST'): "
	read -r email
	if [[ -n "$email" ]]; then
		sed -i "s/root@localhost/$email/g" docker-compose.yml
	else
		echo "no email provided"
	fi
}

init_hostname () {
	echo -n "hostname (leave empty for 'localhost'): "
	read -r host
	if [[ -n  "$host" ]]; then
		sed -i "s/localhost/$host/g" docker-compose.yml
		echo "$host" | sudo tee /etc/hostname
	else
		echo "no hostname provided"
	fi
}

init_firewall () {
	sudo systemctl enable --now ufw
	sudo ufw reset
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
	sudo useradd --create-home --skel /dev/null \
		--home-dir /home/git --shell /usr/bin/git-shell \
		git
	sudo cp -r ./git-shell-commands /home/git
	sudo chown -R git:git /home/git
}

init_web_files () {
	echo -n "web files location (leave empty for './web/html'): "
	read -r location
	if [[ -n "$location" ]]; then
		sed -i "s:./web/index.html:$location:g" docker-compose.yml
	else
		echo "no location provided"
	fi
}

init () {
	# in case of
	docker-compose up -d db

	echo "### create Nextcloud db user"
	init_nextcloud

	echo "### set webmaster email"
	init_webmaster_email

	echo "### set hostname"
	init_hostname

	echo "### set firewall"
	init_firewall

	echo "### create git user"
	init_git

	echo "### set web files location"
	init_web_files

	# and stop
	docker-compose stop db
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
		docker-compose down
		sudo rm -rf ./volumes
		docker volume prune
		sudo rm -rf ./web/html/_site
		sudo rm -rf ./web/html/.jekyll-cache
		;;

	*)
		docker-compose "$@"
		exit 1
		;;
esac
