#### Purpose

This Terraform deployment will set up a floating IP, 2 nodes with HAProxy as load balancers, and a variable number of backend nodes which will have Nginx configured with a server name, and document root. Provisioning will be handled by Terraform and configuration will be done with Ansible.

I highly recommend that a control Droplet be provisioned to execute the scripts rather than running them locally, but the choice is yours to make. For those that will be provisioning a control node, I've included `terragen` which will set up the initial Terraform and Ansible configuration files. Please keep in mind that you can run through the script to create the files and simple execute them manually once the script is done. The script will still require that you create an API token beforehand.

#### Prerequisites

If you're planning to do this locally or install the software manually, you'll need the following:

* You'll need to install [Terraform](https://www.terraform.io/downloads.html) which will be used to handle Droplet provisioning.
* In order to apply configuration changes to the newly provisioned Droplets, [Ansible](http://docs.ansible.com/ansible/intro_installation.html) needs to be installed.
* Ansible's inventory will be handled by Terraform, so you'll need [terraform-inventory](https://github.com/adammck/terraform-inventory).
* We're going to need a DigitalOcean API key. The steps to generate a DigitalOcean API key can be found [here](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2#how-to-generate-a-personal-access-token).
* Use the included `gen_auth_key` script to generate an auth key for your load balancing cluster.


If you're provisioning a control Droplet, you can run the following cloud-config script by passing it in as [user-data](https://www.digitalocean.com/community/tutorials/an-introduction-to-droplet-metadata#digitalocean-control-panel). Rememeber to place in your public SSH key so you can connect to the droplet, and you may change _deployuser_ to any name you'd like.

    #cloud-config

    users:
      - name: deployuser
        shell: /bin/bash
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        ssh-authorized-keys:
          - enter_your_public_key_here

    packages:
      - python
      - python-requests
      - ansible
      - git
      - zip

    runcmd:
      - curl -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/0.11.0/terraform_0.11.0_linux_amd64.zip
      - unzip -d /usr/local/bin/ /tmp/terraform.zip
      - wget -O /tmp/terraform-inventory.zip https://github.com/adammck/terraform-inventory/releases/download/v0.6.1/terraform-inventory_v0.6.1_linux_amd64.zip
      - unzip -d /usr/local/bin/ /tmp/terraform-inventory.zip
      - wget -qO /tmp/doctl.tgz "https://github.com/digitalocean/doctl/releases/download/v1.7.1/doctl-1.7.1-linux-amd64.tar.gz" /usr/local/bin/
      - tar xzvf /tmp/doctl.tgz -C /usr/local/bin/

    package_update: true
    package_upgrade: true

#### Manual Configuration

Let's get Terraform ready to deploy. We're going to be using **terraform.tfvars** to store values required such as API key, project name, SSH data, the number of backend nodes you want, etc. The sample file **terraform.tfvars.sample** has been supplied, just remember to remove the appended _.sample_. Once you have your all of the variables set, Terraform should be able to authenticate and deploy your Droplets.

Next we need to get Ansible set up by heading over to **group\_vars/all**. You can now create a file (any name will do. e.g. *vault*). Declare your **vault_** variables in this file.

We're going to be using ansible-vault to securely store your API key. In terminal, head over to **group\_vars/all**, and execute the following command.

    $ ansible-vault create vault

You will now be able to edit the file and set the values. The file should look something like this:

    ---
    vault_do_token: umvkl89wsxwuuz4a1nyzap5rsyk4un9fza5qokd7nzrn42owfclv8gdqk3k5gzqlz
    vault_ha_auth_key: 0dgivsxomvb80sx3uvd6u42j3920pbvveik007ec8

If needed, you can always go back in and edit the file by simply executing `$ ansible-vault edit vault`. To prevent having to enter in `--ask-vault-pass` every time you execute your playbook, we'll set up your password file and store that outside of the repo. You can do so by running the following command.

    $ echo 'password' > ~/.vaultpass.txt

And set `vault_password_file = ~/.vaultpass.txt` in your ansible.cfg file.

Okay, now everything should be set up and you're ready to start provisioning and configuring your Droplets.

#### Terragen Configuration

Once you have all the Prerequisite software installed or have executed the cloud-config script, you can log into the Droplet through SSH. I recommend you create a workspace directory such as `mkdir -p ~/workspace/project-name`. You can then run the following to clone the repo contents to your Droplet.

    git clone https://github.com/cmndrsp0ck/ha-standard-deploy.git ~/workspace/project-name/

Now all you'll have to do is `cd ~/workspace/project-name/` and execute `./terragen`. You'll be prompted for input such as your project name, your DigitalOcean API token, region, and so on.

#### Deploying

We'll start by using Terraform. Make sure you head back to the repository root directory. You'll need to run `terraform init` to download the terraform plugins like the digitalocean and template providers. Once that's all set up you can run a quick check and create an execution plan by running `terraform plan`.

Once you're ready, use `terraform apply` to build the Droplets and floating IP. This should take about a minute or two depending on how many nodes you're spinning up. Once it finishes up, wait about 45 seconds for the cloud-config commands that were passed in to complete.

We're ready to begin configuring the Droplets. Execute the Ansible playbook from the repository root to configure your Droplets by running the following

    ansible-playbook -i /usr/local/bin/terraform-inventory site.yml

This playbook will install and configure heartbeat, your floating IP re-assignment script, install and configure HAProxy load balancers, and your backend nodes. You should see a steady output which will state the role and step at which Ansible is currently running. If there are any errors, you can easily trace it back to the correct role and section of the task.

#### Follow-up steps

At this point, you will have two droplets with HAProxy configured as load balancers, a floating IP to be re-assigned between the two at any time, and two web nodes which can be used to set up your application code base. Keep in mind that the app nodes configuration is very basic, but the template files and tasks can easily be altered to suit your needs. If you already have Droplets provisioned, you can import them into Terraform, as well as create an image from it and use the image ID to spin up additional nodes. Any additional configuration can simple by done by creating a simple Ansible role, or modifying the existing one.
