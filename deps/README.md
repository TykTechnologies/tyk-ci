# Tyk dependencies
At present,
- Mongo
- Redis 

These dependencies require persistence and run on EC2 instances. The AMIs are built by [packer](https://developer.hashicorp.com/packer/docs "docs") and are based on bullseye.

`base.pkr.hcl` creates an AMI _TykCI Base - Bullseye_ with Ansible installed. This AMI is used as the base for the dependency specific AMI and the configuration for each dependency is done with ansible with playbooks in `playbooks/`. <deps.pkr.hcl> creates AMIs for, 
- Mongo 4.4
- Redis 6.0. 

# TODOs
- external EBS for the EC2 instances
- automation to launch the instances in a place that the compose based tyk deps can access them
