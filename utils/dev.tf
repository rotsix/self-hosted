terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    gandi = {
      version = "~> 2.0"
      source  = "go-gandi/gandi"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "eu-west-3"
}

provider "gandi" {
  key = yamldecode(file("../conf/config.yml")).gandi_key
}

data "http" "arch_ami" {
  # https://wiki.archlinux.org/title/Arch_Linux_AMIs_for_Amazon_Web_Services#REST_API_to_List_AMIs
  url = "https://5nplxwo1k1.execute-api.eu-central-1.amazonaws.com/prod/eu-west-3/x86_64/std/latest"

  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_instance" "sh_dev" {
  ami           = jsondecode(data.http.arch_ami.response_body).arch_amis[0].ami
  instance_type = "t2.small"
  key_name      = "aws"

  provisioner "remote-exec" {
    inline = ["curl 'https://archlinux.org/mirrorlist/?country=FR&protocol=https&ip_version=4' | tail -n 5 | sed 's/^#//g' | sudo tee /etc/pacman.d/mirrorlist"]

    connection {
      host        = self.public_ip
      user        = "arch"
      private_key = file("~/aws.pem")
    }
  }
}

resource "gandi_livedns_record" "dev_franzi_fr" {
  for_each = toset(["dev", "*.dev"])

  zone   = "franzi.fr"
  name   = each.key
  type   = "A"
  values = [aws_instance.sh_dev.public_ip]
  ttl    = 300
}

output "instance_public_ip" {
  description = "public ip"
  value       = aws_instance.sh_dev.public_ip
}
