provider "aws" {
  profile = "default"
  region  = "eu-west-3"
}

resource "aws_instance" "sh_dev" {
  ami           = "ami-0d27a493ef7464778"
  instance_type = "t2.micro"
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

output "instance_public_ip" {
  description = "public ip"
  value       = aws_instance.sh_dev.public_ip
}
