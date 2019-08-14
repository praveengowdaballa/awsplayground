#!/bin/bash
#### Removing unwanted pacakges #### 
for a in polkit chrony dhcp-server dhcp-client dhcp talk rsh tftp-server ftp-server Dovecot snmp telnet xinetd rsync; do sudo yum -y remove $a; echo $?; rpm -e $a; echo; echo; echo; sleep 5 ; done 


