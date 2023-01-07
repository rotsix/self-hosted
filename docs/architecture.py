from diagrams import Diagram, Cluster
from diagrams.custom import Custom
from diagrams.generic.network import Firewall
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.groupware import Nextcloud
from diagrams.onprem.network import Nginx, Traefik


def main():
    with Diagram("", show=False, filename="architecture"):

        with Cluster("Torrent"):
            transmission = Custom("Manage torrent\ndomain.tld:9091", "icons/transmission.png")
            mstream = Custom("Audio streaming\ndomain.tld:3000", "icons/mstream.png")

        with Cluster("Cloud"):
            web_proxy = Nginx("domain.tld")
            web_builder = Custom("Personal homepage", "icons/jekyll.png")

            klaus = Custom("Git web viewer\ngit.domain.tld", "icons/git.png")

            nc = Nextcloud("Personal cloud")
            nc_db = PostgreSQL("psql")
            nc_proxy = Nginx("cloud.domain.tld")

            linkding = Custom("Links\nlinks.domain.tld", "icons/linkding.png")

            [
                web_proxy - web_builder,
                klaus,
                nc_proxy - nc - nc_db,
                linkding,
            ]

        with Cluster("Router"):
            traefik = Traefik("Reverse proxy\ndomain.tld:8080")

        with Cluster("Default"):
            ufw = Firewall("UFW")
            borg = Custom("Backups", "icons/borg.svg")
            # wg = Custom("wg.domain.tld:51820", "icons/wireguard.png")

        [traefik]
        [web_proxy, klaus, nc_proxy]
        [transmission - mstream]
        [ufw - borg]


if __name__ == "__main__":
    main()
