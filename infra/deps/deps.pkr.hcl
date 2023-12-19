# all bullsye based builds in one file so that,
# - can run in parallel
# - reuse data and source blocks

packer {
  required_plugins {
    ansible = {
      version = ">= v1.1.1"
      source  = "github.com/hashicorp/ansible"
    }
    amazon = {
      version = ">=v1.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  common_tags = {
    ou        = "syse"
    purpose   = "cd"
    managedby = "packer"
  }
}

# Mongo 4.4 and Redis 6.0 need bullsye
data "amazon-ami" "bullseye" {
  filters = {
    architecture        = "x86_64"
    name                = "TykCI - Bullseye"
    root-device-type    = "ebs"
    sriov-net-support   = "simple"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["self"]
  region      = "eu-central-1"
}

source "amazon-ebs" "component" {
  region                = "eu-central-1"
  force_delete_snapshot = true
  force_deregister      = true
  instance_type         = "t2.micro"
  source_ami            = "${data.amazon-ami.bullseye.id}"
  ssh_username          = "admin"
  subnet_filter {
    filters = {
      "tag:purpose" = "ci"
      "tag:Type"    = "public"
    }
    most_free = true
    random    = false
  }
  tags     = local.common_tags
  run_tags = local.common_tags
}

# Redis 6.0
build {
  name = "r60"
  source "source.amazon-ebs.component" {
    ami_name = "TykCI Redis 6.0"
  }

  provisioner "ansible-local" {
    playbook_file = "playbooks/r60.yml"
    command       = "sudo ansible-playbook"
  }
}

# Mongo 4.4
build {
  name = "m44"
  source "source.amazon-ebs.component" {
    ami_name = "TykCI Mongo 4.4"
  }

  provisioner "ansible-local" {
    playbook_file = "playbooks/m44.yml"
    command       = "sudo ansible-playbook"
  }
}
