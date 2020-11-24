#!/bin/bash

sudo sed -i.orig -e '/security:/,+3 s/^/#/' /opt/bitnami/mongodb/conf/mongodb.conf
sudo /opt/bitnami/scripts/mongodb/restart.sh
