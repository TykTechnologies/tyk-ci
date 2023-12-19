packer {
  required_plugins {
    amazon = {
      version = ">=v1.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

data "amazon-ami" "bullseye" {
  filters = {
    architecture        = "x86_64"
    name                = "debian-11-*"
    root-device-type    = "ebs"
    sriov-net-support   = "simple"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["136693071363"]
  region      = "eu-central-1"
}

source "amazon-ebs" "base" {
  region                = "eu-central-1"
  force_delete_snapshot = true
  force_deregister      = true
  instance_type         = "t2.micro"
  ssh_username          = "admin"
  subnet_filter {
    filters = {
      "tag:purpose" = "ci"
      "tag:Type"    = "public"
    }
    most_free = true
    random    = false
  }

  run_tags = {
    ou        = "syse"
    purpose   = "cd"
    managedby = "packer"
  }
}

build {
  name = "base-bullseye"
  source "source.amazon-ebs.base" {
    ami_name   = "TykCI - Bullseye"
    source_ami = "${data.amazon-ami.bullseye.id}"
  }

  provisioner "file" {
    destination = "/tmp/ansible.gpg"
    source      = "./ansible.gpg"
  }

  provisioner "file" {
    destination = "/tmp/ansible.list"
    source      = "./ansible.list"
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive"
    ]
    inline = [
      "sudo mv /tmp/ansible.list /etc/apt/sources.list.d/ansible.list",
      "sudo mv /tmp/ansible.gpg /usr/share/keyrings/ansible.gpg",
      "sudo apt-get update && sudo apt-get dist-upgrade -y gnupg",
      "sudo apt-get install -y ansible"
    ]
  }
}
