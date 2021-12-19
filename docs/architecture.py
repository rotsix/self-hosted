from diagrams import Diagram, Cluster
from diagrams.custom import Custom
from diagrams.generic.network import Firewall
from diagrams.onprem.database import PostgreSQL, MariaDB
from diagrams.onprem.groupware import Nextcloud
from diagrams.onprem.network import Nginx


def main():
    with Diagram("", show=False, filename="architecture"):

        with Cluster("Torrent"):
            transmission = Custom("Manage torrent\ndomain.tld:9091", "icons/transmission.png")
            mstream = Custom("Audio streaming\ndomain.tld:3000", "icons/mstream.png")

        with Cluster("Cloud"):
            npm = Custom("Reverse proxy\ndomain.tld:81", "icons/npm.png")
            npm_db = MariaDB("mariadb")

            web_proxy = Nginx("domain.tld")
            web_builder = Custom("Personal homepage", "icons/jekyll.png")

            klaus = Custom("Git web viewer\ngit.domain.tld", "icons/git.png")

            nc = Nextcloud("Personal cloud")
            nc_db = PostgreSQL("psql")
            nc_proxy = Nginx("cloud.domain.tld")

            [
                npm - npm_db,
                web_proxy - web_builder,
                klaus,
                nc_proxy - nc - nc_db,
            ]

        with Cluster("Default"):
            ufw = Firewall("UFW")
            # wg = Custom("wg.domain.tld:51820", "icons/wireguard.png")


        [npm, web_proxy, klaus, nc_proxy]
        [transmission - mstream]
        [ufw]


if __name__ == "__main__":
    main()
