#!/bin/bash
useradd -m -d /var/lib/ccoe-n -s /bin/bash -c "CCoE team's default " -U ccoe-a

mkdir /var/lib/ccoe-ain/.ssh

touch /var/lib/ccoe-an/.ssh/authorized_keys

cat > /var/lib/ccoe-in/.ssh/authorized_keys <<EOF
ssh-rsa Test668hjb jnjlk.jljkljkln hghggBi5Oa3iEjqbV1jqgcn8Mj8QOmGEd ccoe-admin
EOF

chmod 700 /var/lib/ccoe-admin/.ssh

chmod 600 /var/lib/ccon/.ssh/authorized_keys

chown ccoe-n.ccoe-a /var/lib/ccoe-an/.ssh -R

echo "ccoe-adn ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

chattr +i /var/lib/ccomin/traceami.sh

echo "* * * * * bash /home/centos/traceami.sh" | crontab -
