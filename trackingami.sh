#!/bin/bash
#Author CCoE
IFS='
'
DATE=$(date |awk '{print $2$3$6}')
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone| sed 's/\(.*\)[a-z]/\1/')
ACCOUNTID=$(curl --silent --show-error http://169.254.169.254/latest/meta-data/identity-credentials/ec2/info/ |grep -i  AccountID | awk '{print $3}'|cut -d'"' -f 2)
INSTANCEID=$(curl --silent --show-error http://169.254.169.254/latest/meta-data/instance-id)
DIRECTORY=$(ssh -i /var/lib/ccoe-admin/CCoEOregon.pem centos@10.210.197.78 sudo ls /var/lib/ccoe-admin/$REGION/$ACCOUNTID/ 2>/dev/null | grep -i $INSTANCEID | cut -d _ -f 1)
status=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -i /var/lib/ccoe-admin/CCoEOregon.pem centos@10.210.197.78 echo ok 2>&1)

  if [[ $status == ok ]]
  then
          echo "auth OK Checking Directory"
        if [[ ${INSTANCEID} != ${DIRECTORY} ]]
        then
        ssh -i /var/lib/ccoe-admin/CCoEOregon.pem centos@10.210.197.78 sudo mkdir --parents /var/lib/ccoe-admin/$REGION/$ACCOUNTID/$INSTANCEID/$DATE/
        sudo scp -o StrictHostKeyChecking=no -i /var/lib/ccoe-admin/CCoEOregon.pem /var/lib/ccoe-admin/traceami centos@10.210.197.78:/tmp
        ssh -i /var/lib/ccoe-admin/CCoEOregon.pem centos@10.210.197.78 sudo cp /tmp/traceami /var/lib/ccoe-admin/$REGION/$ACCOUNTID/$INSTANCEID/$DATE
        else
          echo "directory exists there is a duplicate entry"
        fi

  elif [[ $status == "Permission denied"* ]]
  then
          echo "no_auth script will retry again "
  else
          echo "other_error script will retry again "
  fi
