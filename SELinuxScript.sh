#!/bin/bash

IFS=$'\n'

if [ -f /boot/grub/grub.cfg ]
then
    sudo cp /boot/grub/grub.cfg /boot/grub/grub.cfg.bak 
    sudo egrep "linux\s+/boot" /boot/grub/grub.cfg |grep -v recovery >> split.txt
    
    for i in `cat split.txt`
    do
	CE=`echo $i | grep selinux`
  	if [[ -z  $CE ]]
	then 
    		sudo sed -i "s|$i|$i selinux=1|g" /boot/grub/grub.cfg
		sudo echo "Updated SELinux Entry." >> "/root/SEStatus.txt"
	else	
		sudo echo "Found SELinux Entry." >> "/root/SEStatus.txt"
	fi

	AE=`echo $i | grep audit`
	if [[ -z $AE ]]
	then
		sudo sed -i "s|$i|$i audit=1|g" /boot/grub/grub.cfg
		sudo echo "Updated Audit Entry." >> "/root/AuditStatus.txt"
	else
		sudo echo "Found Audit Entry." >> "/root/AuditStatus.txt"
	fi
    done
fi

if [ -f /boot/grub2/grub.cfg ]
then
	sudo cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.bak
	sudo egrep "/vmlinuz" /boot/grub2/grub.cfg |grep -v recovery >> g2split.txt

	for i in `cat g2split.txt`
    do
        CE=`echo $i | grep selinux`
        if [[ -z  $CE ]]
        then 
                sudo sed -i "s|$i|$i selinux=1|g" /boot/grub2/grub.cfg
                sudo echo "Updated SELinux Entry." >> "/root/SEStatus.txt"
        else    
                sudo echo "Found SELinux Entry." >> "/root/SEStatus.txt"
        fi
          
        AE=`echo $i | grep audit`
        if [[ -z $AE ]]
        then
                sudo sed -i "s|$i|$i audit=1|g" /boot/grub2/grub.cfg
                sudo echo "Updated Audit Entry." >> "/root/AuditStatus.txt"
        else
                sudo echo "Found Audit Entry." >> "/root/AuditStatus.txt"
        fi
    done


fi

rm -rf split.txt
rm -rf g2split.txt


SETroubleshoot=`sudo yum list --installed | grep -i setroubleshoot`

if [[ ! -z $SETroubleshoot ]]
then
	sudo yum remove setroubleshoot -y
fi

