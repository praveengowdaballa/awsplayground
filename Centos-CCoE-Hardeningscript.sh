#!/bin/bash

set +e

#Author:- CCoE
# Platform Centos
# This Script is from CCoE AMI With Av Integration Project
echo "####################################################"
echo "#######Setting kernel network parameters######"
cat > /etc/sysctl.d/custom-sysctl.conf <<EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.default.accept_ra=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
net.ipv6.conf.all.disable_ipv6=1
EOF

sleep 2
echo "####################################################"
echo "Modified kernel network parameters filename :- custom-sysctl.conf file path :- /etc/sysctl.d"
cat /etc/sysctl.d/custom-sysctl.conf
echo "####################################################"
echo "#### Taking backup /etc/login.defs #################"
cp /etc/login.defs /etc/"login.defs-Backup.$(date +"%F %T")"
chmod 644 /etc/login.defs-Backup*
ls -ltrh /etc/login.defs-Backup*
echo "####################################################"
echo " Before modifying /etc/login.defs Values "
echo "####################################################"
grep PASS_MAX_DAYS  /etc/login.defs | awk 'NR==2'
grep PASS_MIN_DAYS /etc/login.defs | awk 'NR==2'
grep PASS_WARN_AGE /etc/login.defs | awk 'NR==2'
grep PASS_MIN_LEN /etc/login.defs | awk 'NR==2'
echo "####################################################"
echo "####### modifying /etc/login.defs #######"
echo "Setting Password Expiry "
echo "####################################################"
sed -i '/PASS_MAX_DAYS/s/[0-9]\+/365/g' /etc/login.defs
sed -i '/PASS_MIN_DAYS/s/[0-9]\+/1/g' /etc/login.defs
sed -i '/PASS_MIN_LEN/s/[0-9]\+/8/g' /etc/login.defs
sed -i '/PASS_WARN_AGE/s/[0-9]\+/7/g' /etc/login.defs
echo "######### After modifying /etc/login.defs ##########"
echo "####################################################"
grep PASS_MAX_DAYS  /etc/login.defs | awk 'NR==2'
grep PASS_MIN_DAYS /etc/login.defs | awk 'NR==2'
grep PASS_WARN_AGE /etc/login.defs | awk 'NR==2'
grep PASS_MIN_LEN /etc/login.defs | awk 'NR==2'
echo "############################################################"

echo "##### Configuring OpenSSH server ############################"
echo "####### Taking back-up of sshd_config.Path /etc/ssh/sshd_config-backup.Currenttime&date#########"
cp /etc/ssh/sshd_config /etc/ssh/"sshd_config-backup.$(date +"%F %T")"
chmod 644 /etc/ssh/sshd_config-backup*
ls -ltrh /etc/ssh/sshd_config-backup*
echo "Before modifying Changes in /etc/ssh/sshd_config "
echo "####################################################"
grep LogLevel /etc/ssh/sshd_config
grep X11Forwarding /etc/ssh/sshd_config | awk 'NR==1'
grep MaxAuthTries /etc/ssh/sshd_config
grep IgnoreRhosts /etc/ssh/sshd_config
grep HostbasedAuthentication /etc/ssh/sshd_config | awk 'NR==1'
grep PermitEmptyPasswords /etc/ssh/sshd_config
grep PermitUserEnvironment /etc/ssh/sshd_config
grep ClientAliveInterval /etc/ssh/sshd_config
grep ClientAliveCountMax /etc/ssh/sshd_config
grep LoginGraceTime /etc/ssh/sshd_config
grep Ciphers /etc/ssh/sshd_config
grep Banner /etc/ssh/sshd_config
echo "####################################################"
echo "##########Changing sshd_config ##########"
echo "####################################################"
sed -i 's/^.*LogLevel INFO.*$/LogLevel INFO/g' /etc/ssh/sshd_config
sed -i 's/^.*X11Forwarding.*$/X11Forwarding no/g' /etc/ssh/sshd_config
sed -i 's/^.*MaxAuthTries.*$/MaxAuthTries 4/g' /etc/ssh/sshd_config
sed -i 's/^.*IgnoreRhosts yes.*$/IgnoreRhosts yes/g' /etc/ssh/sshd_config
sed -i 's/^.*HostbasedAuthentication no.*$/HostbasedAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/^.*PermitRootLogin.*$/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/^.*PermitEmptyPasswords.*$/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
sed -i 's/^.*PermitUserEnvironment.*$/PermitUserEnvironment no/g' /etc/ssh/sshd_config
sed -i 's/^.* Ciphers and keying*/&\n Ciphers aes256-ctr,aes192-ctr,aes128-ctr/' /etc/ssh/sshd_config
sed -i 's/^.*ClientAliveInterval .*$/ClientAliveInterval 300/g' /etc/ssh/sshd_config
sed -i 's/^.*ClientAliveCountMax .*$/ClientAliveCountMax 0/g' /etc/ssh/sshd_config
sed -i 's/^.*LoginGraceTime .*$/LoginGraceTime 60/g' /etc/ssh/sshd_config
sed -i 's|^.*Banner none*|Banner /etc/ssh/warningtext|g' /etc/ssh/sshd_config
echo "############### Setting Up Banner ###################"
sleep 2
touch /etc/ssh/warningtext
sleep 2
cat > /etc/ssh/warningtext <<EOF
###################################################################
#               Authorized access only!                           #
#  Disconnect IMMEDIATELY if you are not an authorized user!!!    #
#  All actions Will be monitored and recorded by Micro Focus      #
#  By PSDC CCoE                                                   #
###################################################################
EOF
sleep 2
service sshd restart
chmod 600 /etc/ssh/warningtext
echo "###################################################"

echo "After  modifying Changes in /etc/ssh/sshd_config "

grep LogLevel /etc/ssh/sshd_config
grep X11Forwarding /etc/ssh/sshd_config | awk 'NR==1'
grep MaxAuthTries /etc/ssh/sshd_config
grep IgnoreRhosts /etc/ssh/sshd_config
grep HostbasedAuthentication /etc/ssh/sshd_config | awk 'NR==1'
grep PermitEmptyPasswords /etc/ssh/sshd_config
grep PermitUserEnvironment /etc/ssh/sshd_config
grep ClientAliveInterval /etc/ssh/sshd_config
grep ClientAliveCountMax /etc/ssh/sshd_config
grep LoginGraceTime /etc/ssh/sshd_config
grep Ciphers /etc/ssh/sshd_config
grep Banner /etc/ssh/sshd_config
cat /etc/ssh/warningtext
echo "####################################################"
echo "# Setting permissions on /tmp 1777"
chmod 1777 /tmp
yum install awscli -y

echo "####################################################"
#echo "# Remove Uncessary/Unneeded Packages/Programs ######"
#for a in mcstrans telnet-server telnet rsh-server rsh ypbind ypserv tftp tftp-server talk talk-server xinetd openldap-servers openldap-clients bind vsftpd httpd dovecot net-snmp setroubleshoot; do yum -y remove $a 2>&1 /dev/null; done

#for a in autofs avahi-daemon avahi-dnsconfd  cups gpm  portmap rhnsd sendmail daytime-dgram daytime-stream echo-dgram echo-stream tcpmux-server; do systemctl disable $a 2>&1 /dev/null; done

