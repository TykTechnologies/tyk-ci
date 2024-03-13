#!/bin/bash

tee -a ~ec2-user/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdWj1jk3WpWqMGF9pueAYSS/CJgBIii1Wmfg6QgdrTFVjTwLPAPeWn1CXQyETzvWkJGrQzCh5lgD/gR6IieWuSGy2e99FUAxzUprLnML3A1gyXWGTNfv5PQkHSW3VEa/c38a8cQHIKJsMgXYDwecTC8VlWZyGbrlfj04z7Az2IXgIQmMSlUij1ViP/ESk0Sj9KXP/hD4WBSUnVeUwhCWjEqLIxk5dMJoJnrk763jX62gIEUXKwLr2SLTd4skt9wH1fp85BkFPegjfSoJEkeopjB7crpZAKDUrn+KZDYfUQjp0eYt2ULNDqKHn82sHzwS1GhFMBv5WMETx5LUdwBPQR leo
EOF

dnf update
dnf install -y docker
systemctl start enable --now docker
usermod -aG docker ec2-user

# Install compose plugin for all users
mkdir -p /usr/local/lib/docker/cli-plugins

curl -sL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) \
  -o /usr/local/lib/docker/cli-plugins/docker-compose

# Set ownership to root and make executable
chown root:root /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
