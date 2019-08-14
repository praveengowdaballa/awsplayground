#!/bin/bash
useradd -m -d /var/lib/ccoe-admin -s /bin/bash -c "CCoE team's default " -U ccoe-admin

mkdir /var/lib/ccoe-admin/.ssh

touch /var/lib/ccoe-admin/.ssh/authorized_keys

cat > /var/lib/ccoe-admin/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAK+CdRSWZqxbrc+5Vo7YH98pRksuQik7HSpTfPV5EHEMw3SW8tVclVLj2Ip1ZuwkECsyxhS0rzf7RlijcpPipEYa3t0cG6zNrqqFz+PQZeeeY+3BoxKveR3lCFHY2AWjj2IA6bz2whoR3bVPYPu8e1SXupz+FrXm6KU4EHJHqhNdFNhNAxQcpiupXs0jlDST2rO0xWQWLp6DbGI4G5KlXIxP+MDlrCAC3j+/svn4WU/5kwi1SVfOT/mc6j+vukQnNOPka7tw0CevQLyb31M8YakMyNTyuKkj+4ZoSbwyoh7qxzw7sl8CQLbt6Bi5Oa3iEjqbV1jqgcn8Mj8QOmGEd ccoe-admin
EOF

chmod 700 /var/lib/ccoe-admin/.ssh

chmod 600 /var/lib/ccoe-admin/.ssh/authorized_keys

chown ccoe-admin.ccoe-admin /var/lib/ccoe-admin/.ssh -R

echo "ccoe-admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

chattr +i /var/lib/ccoe-admin/traceami.sh

echo "* * * * * bash /home/centos/traceami.sh" | crontab -
