from diagrams import Diagram, Cluster
from diagrams.custom import Custom
from diagrams.generic.network import Firewall
from diagrams.onprem.network import Nginx, Traefik


def main():
    with Diagram("", show=False, filename="architecture"):

        with Cluster("Torrent"):
            transmission = Custom(
                "Manage torrent\ndomain.tld:9091", "icons/transmission.png"
            )
            mstream = Custom("Audio streaming\ndomain.tld:3000", "icons/mstream.png")

            [transmission - mstream]

        with Cluster("Cloud"):
            web_proxy = Nginx("domain.tld")
            web_builder = Custom("Personal homepage", "icons/jekyll.png")
            klaus = Custom("Git web viewer\ngit.domain.tld", "icons/git.png")
            linkding = Custom("Links\nlinks.domain.tld", "icons/linkding.png")
            baikal = Custom("DAV\ndav.domain.tld", "icons/baikal.png")
            syncthing = Custom("Sync service", "icons/syncthing.png")
            files = Custom("Files\nfiles.domain.tld", "icons/filebrowser.png")

            [web_proxy - web_builder, klaus, linkding, files - baikal - syncthing]

        with Cluster("Router"):
            traefik = Traefik("Reverse proxy\ndomain.tld:8080")
            [traefik]

        with Cluster("Default"):
            ufw = Firewall("UFW")
            borg = Custom("Backups", "icons/borg.svg")
            # wg = Custom("wg.domain.tld:51820", "icons/wireguard.png")

            [ufw - borg]


if __name__ == "__main__":
    main()
