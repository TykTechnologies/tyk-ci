#!/bin/bash

tee -a ~ec2-user/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8ALCOd33gsB8vao1eFdiwsTg9hDqnHHVEKWrfMGJGB7ZXvUfc97ge3Lz9GroSjVZvx94uLWCoGO886RGJ35dHFcLztpa1x1gf6QeK2GqtFU2+CVJ8es0QP0//ADcGoEYawSSrcfBDCHx/DQLrIN/d48G20vNZ0JSdqPN26seZeRhe33nSZZ+j55O+Ss4R43N90o32r9WvbYqUHoe+qzpvInz2RWSjx2xF457FeMNbeKujq9pZewmRnIZ/QmiMfVki/W61PQK/20sMFn+pad83wtmzivJjnMd3I7xKWBJMEKrnP2KfqXmFIYDPg/pmDCt/Huz4dy4I9dOqUQz7I5iv ilijabojanovic@Ilijas-MacBook-Pro.local
EOF

sudo tee -a /etc/yum.repos.d/mongo-org.repo <<EOF
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF

sudo yum install -y mongodb-org-shell && yum update -y

sudo groupadd tyk

// TODO: implement TrustedUserCAKeys with cfssl, see https://github.com/drewfarris/sample-cfssl-ca
