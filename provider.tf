# Set up provider details
variable "do_token" {}

variable "project" {}

variable "region" {}

variable "image_slug" {}

variable "keys" {}

variable "private_key_path" {}

variable "ssh_fingerprint" {}

variable "public_key" {}

variable "node_count" {}

provider "digitalocean" {
  token = "${var.do_token}"
}
