# haproxy lb and web node set up

resource "digitalocean_droplet" "load_balancer" {
	count = 2
	image = "ubuntu-14-04-x64"
	name = "${var.project}-lb-${count.index + 1}"
	region = "${var.region}"
	size = "1gb"
	private_networking = true
	ssh_keys = ["${var.keys}"]
	user_data = "${template_file.user_data.rendered}"
	connection {
		user = "root"
		type = "ssh"
		key_file = "${var.private_key_path}"
		timeout = "2m"
	}
}

resource "digitalocean_droplet" "web_node" {
	count = 2
	image = "ubuntu-14-04-x64"
	name = "${var.project}-web-${count.index + 1}"
	region = "${var.region}"
	size = "512mb"
	private_networking = true
	ssh_keys = ["${var.keys}"]
	user_data = "${template_file.user_data.rendered}"
	connection {
		user = "root"
		type = "ssh"
		key_file = "${var.private_key_path}"
		timeout = "2m"
	}
}

resource "template_file" "user_data" {
  template = "${file("${path.module}/config/cloud-config.yaml")}"

  vars {
    public_key = "${var.public_key}"
  }
}

resource "digitalocean_floating_ip" "fip" {
	region = "${var.region}"
	droplet_id = "${digitalocean_droplet.load_balancer.0.id}"
}
