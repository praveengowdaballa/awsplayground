#!/bin/bash



for i in  samba samba-common-bin samba-client samba-winbind samba-winbind-clients sssd-krb5* sssd-krb5-common pam_krb5  wget unzip dnsutils dos2unix kernel; do sudo yum install -y $i ; done


uname -msr
for i in `sudo  ps -A | grep apt | awk '{print $1}'` ; do sudo kill -9 $i ; done
sudo yum install kernel -y

sudo mkdir /root/yum_backup
sudo cp -ar /etc/yum.repos.d/*.repo /root/yum_backup

echo "Backedup Repo files details are below."
sudo ls /root/yum_backup


sudo mount /dev/xvdd1 /tmp

echo "sudo yum -y remove polkit*" >> /etc/rc.local

echo "Checking Polkit package"
sudo yum repolist
sudo yum list polkit
sudo yum remove -y polkit

echo "Changing SELinux Config to Permissive."
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

echo "SELinux Status after the modification."
sudo egrep ^SELINUX /etc/selinux/config

echo "Diabling NetworkManager & Enabling winbind service"
sudo systemctl disable NetworkManager
sudo systemctl enable winbind

sudo systemctl unmask tmp.mount


echo ""
echo "====================================="
echo "Removing History and authorized Keys"
echo "====================================="
echo " "
sudo find /root/.*history /home/*/.*history -exec rm -f {} \;
sudo find / -name "authorized_keys" –exec rm –f {} \;
sudo find /root/ /home/*/ -name .cvspass –exec rm –f {} \;
sudo find /root/.subversion/auth/svn.simple/ /home/*/.subversion/auth/svn.simple/ -exec rm –rf {} \;
sudo find / -name "authorized_keys" -print -exec cat {} \;

