#!/bin/bash
#Author CCoE

INSTANCEID=$(curl --silent --show-error http://169.254.169.254/latest/meta-data/instance-id)

OUTPUT=$(grep InstanceID  /var/lib/ccoe-admin/traceami | awk '{print $2}'|tail -n 1)

if [[ ${INSTANCEID} != ${OUTPUT} ]]; then

echo "Successful"

echo "##################### `date` #########################" >> /var/lib/ccoe-admin/traceami

AMIID=$(curl --silent --show-error http://169.254.169.254/latest/meta-data/ami-id)


INSTANCETYPE=$(curl --silent --show-error http://169.254.169.254/latest/meta-data/instance-type)

ACCOUNTID=$(curl --silent --show-error http://169.254.169.254/latest/meta-data/identity-credentials/ec2/info/ |grep -i  AccountID | awk '{print $3}'|cut -d'"' -f 2)



echo AMIID= $AMIID >> /var/lib/ccoe-admin/traceami

echo InstanceID= $INSTANCEID >> /var/lib/ccoe-admin/traceami

echo InstanceType= $INSTANCETYPE >> /var/lib/ccoe-admin/traceami

echo AccountID= $ACCOUNTID >> /var/lib/ccoe-admin/traceami
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone| sed 's/\(.*\)[a-z]/\1/')

AMINAME=$(aws ec2 describe-images --image-ids $AMIID --region $REGION --output text  --query 'Images[*].[Name]' 2>/dev/null )

AMIDESCRIPTION=$(aws ec2 describe-images --image-ids $AMIID --region $REGION --output text --query 'Images[*].[Description]' 2>/dev/null)

AMILOCATION=$(aws ec2 describe-images --image-ids $AMIID --region $REGION --output text --query 'Images[*].[ImageLocation]' 2>/dev/null)

AMICREATIONDATE=$(aws ec2 describe-images --image-ids $AMIID --region $REGION --output text --query 'Images[*].[CreationDate]' 2>/dev/null)

if [[ ! -z $AMINAME ]];then

echo AMINAME=  $AMINAME >> /var/lib/ccoe-admin/traceami




fi

if [[ ! -z $AMIDESCRIPTION ]];then

echo AMIDescription= $AMIDESCRIPTION >> /var/lib/ccoe-admin/traceami

fi

if [[ ! -z $AMICREATIONDATE ]];then

echo AMICreationDate= $AMICREATIONDATE >> /var/lib/ccoe-admin/traceami

fi

if [[ ! -z $AMILOCATION ]];then

echo AMILocation= $AMILOCATION >> /var/lib/ccoe-admin/traceami

fi


echo "####################### `date` ###################" >> /var/lib/ccoe-admin/traceami
fi

chattr +a /var/lib/ccoe-admin/traceami


