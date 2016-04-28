## HA Proxy deployment
---

This Terraform deployment will set up a floating IP, 2 HA Proxy nodes, 2 web nodes. Provisioning will be handled by Terraform and configuration will be done with Ansible.

### Prerequisites
---
* You'll need to install [Terraform](https://www.terraform.io/downloads.html) which will be used to handle Droplet provisioning.
* In order to apply configuration changes to the newly provisioned Droplets, [Ansible](http://docs.ansible.com/ansible/intro_installation.html) needs to be installed.
* Ansible's inventory will be handled by Terraform, so you'll need [terraform-inventory](https://github.com/adammck/terraform-inventory).

### Provisioning Droplets
---
1. We're going to be using **variables.tf** to store values required such as API key, project name, SSH data, etc. The sample file **variables.tf.sample** has been supplied.
2. Edit **haproxy.tf** and set the number of web nodes you want to provision.
3. Use `terraform apply` to build the Droplets and floating IP.

### Configure Droplets
---
1. Copy **group_vars/load_balancer.sample** to **group_vars/load_balancer**.
2. Create Ansible node configuration:
    1. Un-comment *do_token* and place in your API token.
    2. Use `gen_auth_key` to generate an auth key for your load balancing cluster, un-comment and fill in *ha_auth_key* with the generated token.
3. Execute the Ansibile playbook to configure your Droplets: `ansible-playbook -i /usr/local/bin/terraform-inventory site.yml`

### Follow-up steps
---
At this point, you will have two droplets with HA Proxy configured, a floating IP to be re-assigned between the two at any time, and two web nodes which can be used to set up your application code base. If you already have Droplets provisioned, you can create an image from it and use the image ID to spin up additional nodes. Any additional configuration can simple by done by creating a simple Ansible role it to configure any new nodes and adjust the haproxy.cfg file to include them. 
