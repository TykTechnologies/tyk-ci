#!/bin/bash

tee -a ~ec2-user/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8ALCOd33gsB8vao1eFdiwsTg9hDqnHHVEKWrfMGJGB7ZXvUfc97ge3Lz9GroSjVZvx94uLWCoGO886RGJ35dHFcLztpa1x1gf6QeK2GqtFU2+CVJ8es0QP0//ADcGoEYawSSrcfBDCHx/DQLrIN/d48G20vNZ0JSdqPN26seZeRhe33nSZZ+j55O+Ss4R43N90o32r9WvbYqUHoe+qzpvInz2RWSjx2xF457FeMNbeKujq9pZewmRnIZ/QmiMfVki/W61PQK/20sMFn+pad83wtmzivJjnMd3I7xKWBJMEKrnP2KfqXmFIYDPg/pmDCt/Huz4dy4I9dOqUQz7I5iv ilijabojanovic@Ilijas-MacBook-Pro.local
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCi94TW0M9UuW3SKmWLUR/aBUXOS7XdQ5Rs/Gixr4R6yrClZq17ONVRkUxsj0eCTOW30pSqvroKv00Q4pd7JD2g9cz+o0nCeFzN0jl/7PCy5iOkmr0DBz3XDMKDvGduyadFn8Um+ySFsqBa9H8v2KZL2BQmzGEiD5aY30HxNbdyUaPBkQQ/i80STP6fRuHMWLFRIlkobzKyXdFsU8FCjcJEgRw3Lgy1cbE93K0JpDK+GstRG3tOwnXpvloTMncKZatmxhZaSJbnClVBFljeVwxUM+dVhp+RXwaKNkQAr9a5iRH+oUdbuwcwuxyyrmaFcApQDtddtZoV8fIs/In31JdAbEdROR92C2BVpb8GbUCl6MYSHiydfzxQlFNDWdfqv+cLE4IYqJX2YGk41D4APsNnZQcFcHxkjhAFw4kgy/Et+kKNlDFla+yJZItCKRFYsCwzM/3XTOZwK1LwWcsCnw1Lnf6nqVKwA/xa4MBzeHyX0tkkZx2WvzBTRwxEJEgBfrcMjipdvsdYhbVQYCvcAwMMUMjSGnLDfpV5duh7n1bTqNi/3Ogrb5+1OVil0o7ijy0KFOXYZA7m6DZ5zQeD5W8p//gGXCLAqFO/RqEeVfSoh5l0/2i2Zipdmg/e2CNC67Tguh0WhqnrwLf6ipGbJgwppG2RenWmyUrop3VD/f4Wgw== kiki@Estebans-MacBook-Pro.local
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB20kCeQniG3EmynWupaq1SWwwHQG+wj4GQYj3+xY9k4 alok@gauss
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
