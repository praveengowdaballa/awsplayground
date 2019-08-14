#!/bin/bash

VERSION=$(cat /etc/os-release | grep -i version_id | awk -F"=" '{print $2}' | sed -e 's/"//g' | egrep '^[[:digit:]]' -o)

echo "Version:#${VERSION}#"

if test "$VERSION" == '7' 
then 
	sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 
elif test "$VERSION" == '6' 
then 
	sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm 
fi

sudo lsblk

sudo yum repolist
sudo cat /etc/yum.repos.d/epel*.repo
sudo yum -y install ansible
sudo yum -y install lvm2

sudo yum install auditd audispd-plugins acct -y
sudo service auditd restart
