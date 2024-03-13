#!/bin/bash

#sleep 2m
sudo su - root

dnf install -y amazon-efs-utils

# These are actually terraform variable interpolations for a terraform template_file
efs_id="${efs_id}"
mount_point="${mount_point}"

mkdir -p $mount_point
mount -t efs $efs_id:/ $mount_point

# Edit fstab so EFS automatically loads on reboot
echo $efs_id:/ $mount_point efs defaults,_netdev 0 0 >> /etc/fstab
