#!/bin/bash

sudo su - root

cat > /etc/yum.repos.d/mongo-org.repo <<EOF
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF

yum install -y mongodb-org-shell && yum update -y

groupadd tyk

// TODO: implement TrustedUserCAKeys with cfssl, see https://github.com/drewfarris/sample-cfssl-ca
