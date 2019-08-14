#!/bin/bash
#Script to install McAfee Agent


BUCKET="hpe-automation-deployment"
BUCKET_PATH="/PPM-Bootstrap"
BUCKET_REGION="us-west-2"

rc=`rpm -q MFErt MFEcma`
if [ $? -eq 0 ];then rc1=0;else rc1=1;fi
rc2=`ps aux | grep -v grep| grep masvc| wc -l | awk '{print $1}'`

if [ $rc1 -ne 0 ]
then
	wget "https://s3-${BUCKET_REGION}.amazonaws.com/${BUCKET}/tools/5.0.6_McafeeAgent/agentPackages.zip" -O "/tmp/agentPackages.zip"
	unzip -o /tmp/agentPackages.zip -d /tmp/
	sh /tmp/install.sh -i
	if [ $? -eq 0 ];then echo "Installation of McAfee Agent Successful..";else "Failed to install McAfee Agent...";fi

elif [ $rc1 -eq 0 -a $rc2 -eq 0 ];then echo "McAfee Agent Installed already... CMA Agent Service is not running...";

else
	echo "McAfee Agent Already Installed on this machine... Agent service is running..."
fi

service cma stop

