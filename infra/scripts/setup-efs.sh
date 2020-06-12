#!/bin/bash

#sleep 2m
sudo su - root

# Install AWS EFS Utilities
yum install -y amazon-efs-utils

# Mount EFS
mkdir /efs
efs_id="${efs_id}"
mount -t efs $efs_id:/ /efs

# Edit fstab so EFS automatically loads on reboot
echo $efs_id:/ /efs efs defaults,_netdev 0 0 >> /etc/fstab
