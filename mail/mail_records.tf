terraform {
  required_providers {
    gandi = {
      version = "~> 2.0"
      source  = "go-gandi/gandi"
    }
  }
}

provider "gandi" {
  key = yamldecode(file("../conf/config.yml")).gandi_key
}

variable "mx" {}
variable "txt" {}
variable "txt_dmarc" {}
variable "domainkeys" {}

resource "gandi_livedns_record" "mx_mail" {
  zone   = "franzi.fr"
  name   = "@"
  type   = "MX"
  values = var.mx
  ttl    = 1800
}

resource "gandi_livedns_record" "txt" {
  zone   = "franzi.fr"
  name   = "@"
  type   = "TXT"
  values = var.txt
  ttl    = 1800
}

resource "gandi_livedns_record" "txt_dmarc" {
  zone   = "franzi.fr"
  name   = "_dmarc"
  type   = "TXT"
  values = [var.txt_dmarc]
  ttl    = 1800
}

resource "gandi_livedns_record" "domainkeys" {
  for_each = toset(["", "2", "3"])

  zone   = "franzi.fr"
  name   = "protonmail${each.key}._domainkey"
  type   = "CNAME"
  values = ["protonmail${each.key}.domainkey.${var.domainkeys}"]
  ttl    = 1800
}
