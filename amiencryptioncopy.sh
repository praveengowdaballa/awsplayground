#!/bin/bash
#
# Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

set -o errexit




##### Function #########
usage()
{
    echo " Usage: ${0} -s profile -d profile -a ami_id [-k key] [-l source region] [-r destination region] [-n]
    -s,               AWS CLI profile name for AMI source account.
    -d,               AWS CLI profile name for AMI destination account.
    -a,               ID of AMI to be copied, Source AMI ID.
    -l,               Region of the AMI to be copied, Source Region.
    -r,               Destination region for copied AMI.
    -n,               Enable ENA support on new AMI. (Optional)
    -t,               Copy Tags. (Optional)
    -k,               Specific KMS Key ID for snapshot re-encryption in target AWS account. (Optional)
    -h,               Show this message.
By default, the currently specified region for the source and destination AWS CLI profile will be used, and the default Amazon-managed KMS Key for EBS
    "
}

COLOR='\033[1;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color


die()
{
    BASE=$(basename -- "$0")
    echo -e "${RED} $BASE: error: $@ ${NC}" >&2
    exit 1
}

# Check if source and destination AMI_Copy KMS CMK exists in target regions
#To get KMS Key-ID using the KMS Key AliasName

Create_KMS_Key ()
{
if [ -f ${file} ]; then
New_KMS_KeyID="$(${4} aws kms create-key --region $2 --policy file://$3 --no-bypass-policy-lockout-safety-check --query "KeyMetadata.KeyId" --output text || die "Failed to create KMS Key at Account:$1,Region:$2")"
New_KMS_KeyAliasName="$(${4} aws kms create-alias --alias-name alias/CCoE-Encrypted-AMI-CopyKey --target-key-id ${New_KMS_KeyID} --region $2 || die "Failed to create KMS AliasName for created Key $New_KMS_KeyID at Account:$1,Region:$2")"
echo "${New_KMS_KeyID}"
else
die "CCoE Policy file is not available"
fi
}

Verify_KMS_Key()
{
CCoE_KMS_Key_Alias="\`alias/CCoE-Encrypted-AMI-CopyKey\`"
AMI_COPY_SRCKEY="$(${SRC_STSEXEC} aws kms list-aliases --region ${SRC_REGION} --query 'Aliases[?AliasName=='${CCoE_KMS_Key_Alias}']' |jq -r '.[].TargetKeyId' || die "Failed to verify KMS Key at Account:${SRC_PROFILE},Region:${SRC_REGION}")"

if [ "${AMI_COPY_SRCKEY}x" != x ];then
echo -e "${COLOR}Source KMS Key Exsist and avilable at SRC_Profile:${SRC_PROFILE},SRC_Region:${SRC_REGION} and SRC_KMS Key:${NC} ${AMI_COPY_SRCKEY}"
else
echo -e "${COLOR}Source KMS Key Not Exsist or Disabled at SRC_Profile:${SRC_PROFILE} and SRC_Region:${SRC_REGION}${NC} "
echo -e "${COLOR}Creating New KMS Key${NC}"
#
file="./CCoE_policy_Template"
cp ${file} ${file}_${SRC_PROFILE}
Policy_File="${file}_${SRC_PROFILE}"
sed -i "s/DST_PROFILE/${SRC_PROFILE}/" ${file}_${SRC_PROFILE}
#

AMI_COPY_SRCKEY=`Create_KMS_Key ${SRC_PROFILE} ${SRC_REGION} ${Policy_File} "${SRC_STSEXEC}"`
echo "Verify KMS Key:$AMI_COPY_SRCKEY"
fi

AMI_COPY_DSTKEY="$(${DST_STSEXEC} aws kms list-aliases --region ${DST_REGION} --query 'Aliases[?AliasName=='${CCoE_KMS_Key_Alias}']' |jq -r '.[].TargetKeyId'|| die "Failed to verify KMS Key at Account:${SRC_PROFILE},Region:${SRC_REGION}")"

if [ "${AMI_COPY_DSTKEY}x" != x ];then
echo -e "${COLOR}Destination KMS Key Exsist and avilable at DST_Profile:${DST_PROFILE},DST_Region:${DST_REGION} and DST_KMS Key:${NC} ${AMI_COPY_DSTKEY}"
else
echo -e "${COLOR}Destination KMS Key Not Exsist or Enabled at DST_Profile:${DST_PROFILE} and DST_Region:${DST_REGION} ${NC}"
#Create_KMS_Key ${DST_PROFILE} ${DST_REGION}
file="./CCoE_policy_Template"
cp ${file} ${file}_${DST_PROFILE}
Policy_File="${file}_${DST_PROFILE}"
sed -i "s/DST_PROFILE/${DST_PROFILE}/" ${file}_${DST_PROFILE}

AMI_COPY_DSTKEY=`Create_KMS_Key ${DST_PROFILE} ${DST_REGION} ${Policy_File} "${DST_STSEXEC}"`
echo $AMI_COPY_DSTKEY
fi

}


Verify_AMI_Snapshot_KMS ()
{


# Describes the source AMI and stores its contents
AMI_DETAILS=$(${SRC_STSEXEC} aws ec2 describe-images --region $2 --image-id $3  --query 'Images[0]'| jq 'del (.ProductCodes)'|| die "Unable to describe the AMI in the source account. Aborting.")
# Retrieve the snapshots and key ID's
SNAPSHOT_IDS=$(echo ${AMI_DETAILS} | jq -r '.BlockDeviceMappings[] | select(has("Ebs")) | .Ebs.SnapshotId' || die "Unable to get the encrypted snapshot ids from AMI. Aborting.")
echo -e "${COLOR}Snapshots found:${NC}" ${SNAPSHOT_IDS}

KMS_KEY_IDS=$(${SRC_STSEXEC} aws ec2 describe-snapshots --region $2  --snapshot-ids ${SNAPSHOT_IDS} --query 'Snapshots[?Encrypted==`true`]' | jq -r '[.[].KmsKeyId] | unique | .[]' || die "Unable to get KMS Key Ids from the snapshots. Aborting.")
}
###### End Function #########



# Checking dependencies
command -v jq >/dev/null 2>&1 || die "jq is required but not installed. Aborting. See https://stedolan.github.io/jq/download/"
command -v aws >/dev/null 2>&1 || die "aws cli is required but not installed. Aborting. See https://docs.aws.amazon.com/cli/latest/userguide/installing.html"



while getopts ":s:d:a:l:r:k:nth" opt; do
    case $opt in
        h) usage && exit 1
        ;;
        s) SRC_PROFILE="$OPTARG"
        ;;
        d) DST_PROFILE="$OPTARG"
        ;;
        a) AMI_ID="$OPTARG"
        ;;
        l) SRC_REGION="$OPTARG"
        ;;
        r) DST_REGION="$OPTARG"
        ;;
        k) CMK_ID="$OPTARG"
        ;;
        n) ENA_OPT="--ena-support"
        ;;
        t) TAG_OPT="y"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
        ;;
    esac
done


#Added on 25July- For Jenkins Jon Role based authentication
MBA_ROLEARN="arn:aws:iam::356083436205:role/DevOps-Automation"
SRC_ROLEARN="arn:aws:iam::$SRC_PROFILE:role/HPE-Cloud-Governance-Parent-Account-Access-Role"
DST_ROLEARN="arn:aws:iam::$DST_PROFILE:role/HPE-Cloud-Governance-Parent-Account-Access-Role"

SRC_STSEXEC="stsexec --rolearn $MBA_ROLEARN --rolearn $SRC_ROLEARN"
DST_STSEXEC="stsexec --rolearn $MBA_ROLEARN --rolearn $DST_ROLEARN"


# Validating Input parameters
if [ "${SRC_PROFILE}x" == "x" ] || [ "${DST_PROFILE}x" == "x" ] || [ "${AMI_ID}x" == "x" ] || [ "${SRC_REGION}x" == "x" ] || [ "${DST_REGION}x" == "x" ]; then
    usage
    exit 1;
fi


#Verify Account Access and Gets the destination account ID 

SRC_ACCT_ID=$(${SRC_STSEXEC} aws sts get-caller-identity --query Account --output text || die "Unable to get the Source account ID. Check access to ${SRC_PROFILE}. Aborting.")
DST_ACCT_ID=$(${DST_STSEXEC} aws sts get-caller-identity --query Account --output text || die "Unable to get the destination account ID.Check access to ${DST_PROFILE}. Aborting.")

#Printing Source and Destination Account ID and Region

echo -e "${COLOR}Source account ID:${NC}" ${SRC_ACCT_ID}
echo -e "${COLOR}Destination account ID:${NC}" ${DST_ACCT_ID}
echo -e "${COLOR}Source region:${NC}" ${SRC_REGION}
echo -e "${COLOR}Destination region:${NC}" ${DST_REGION}



#This below line to find out whether snopshot are encrypted or not

Verify_AMI_Snapshot_KMS ${SRC_PROFILE} ${SRC_REGION} ${AMI_ID} 

#
if [ "${KMS_KEY_IDS}x" != "x" ] ; then
### Check if CMK provided as Input, optional parameter, check destination CMK exists in target region 
if [ "${CMK_ID}x" != "x" ]; then
    if [ "$(${DST_STSEXEC} aws --region ${DST_REGION}  kms describe-key --key-id ${CMK_ID} --query 'KeyMetadata.Enabled' --output text)" == "True" ]; then
        AMI_COPY_DSTKEY="${CMK_ID}"
	echo -e "${COLOR}Validated destination KMS Key:${NC} ${AMI_COPY_DSTKEY}"
	
    else
        die "KMS Key ${AMI_COPY_DSTKEY} non existent, in the wrong region, or not enabled. Aborting."
    fi

    CMK_OPT="--kms-key-id ${AMI_COPY_DSTKEY}"
	echo "Destination KMS Key: ${AMI_COPY_DSTKEY}"
else
### Verify KMS Key from Source and Destination Accounts if optional Key not provided
echo -e "${COLOR} Check the CCoE created KMS key, If not present,it will create${NC}"
Verify_KMS_Key
CMK_OPT="--kms-key-id ${AMI_COPY_DSTKEY}"
echo "Destination KMS Key:${AMI_COPY_DSTKEY}"
fi
###

  echo -e "${COLOR}Customer managed KMS key(s) used on source AMI:${NC}" ${KMS_KEY_IDS}
  # Iterate over the Keys and create the Grants
  while read key; do
      KEY_MANAGER=$(${SRC_STSEXEC} aws kms describe-key --key-id ${key} --query "KeyMetadata.KeyManager" --region ${SRC_REGION} --output text || die "Unable to retrieve the Key Manager information. Aborting.")
      if [ "${KEY_MANAGER}" == "AWS" ] ; then

   echo -e "${COLOR} The Default AWS/EBS key is being used by the snapshot. Unable to proceed. Hence Creating AMI with customer created CMK.${NC}"
#Copy AMI to Encrypt Using Customer Managed KMS on Same Region
AMI_SRC_NAME=$(${SRC_STSEXEC} aws ec2 --region ${SRC_REGION} describe-images --image-id ${AMI_ID} --query 'Images[0]' |jq -r '.Name')
AMI_SRC_Local=$(${SRC_STSEXEC} aws ec2 copy-image --source-image-id ${AMI_ID} --source-region ${SRC_REGION} --region ${SRC_REGION} --name ${AMI_SRC_NAME} --encrypted --kms-key-id ${AMI_COPY_SRCKEY} --output text || die "Unable to Copy with CCoE Created KMS Key")
	echo "${AMI_SRC_Local}" 
	echo "${COLOR} Encrypting with CCoE CMK on  ${SRC_PROFILE} and ${SRC_REGION} region, This process will take sometime...${NC}"
	${SRC_STSEXEC} aws ec2 wait image-available --image-ids ${AMI_SRC_Local} --region ${SRC_REGION}
	echo "${COLOR}Encrypted with CCoE CMK Completed... ${NC}"
	key="${AMI_COPY_SRCKEY}"
      fi
     ${SRC_STSEXEC} aws kms --region ${SRC_REGION} create-grant --key-id $key --grantee-principal $DST_ACCT_ID --operations DescribeKey Decrypt CreateGrant > /dev/null || die "Unable to create a KMS grant for the destination account. Aborting."
      echo -e "${COLOR}Grant created for:${NC}" ${key}
	if [ -z ${AMI_SRC_Local} ]; then
	AMI_SRC_Local=${AMI_ID}
	fi
	echo ${AMI_SRC_Local}
  done <<< "${KMS_KEY_IDS}"
else
  echo -e "${COLOR}No encrypted EBS Volumes were found in the source AMI!${NC}"
AMI_SRC_Local=${AMI_ID}
fi

#Capturing Newly Created AMI Details
if [[ $AMI_ID != $AMI_SRC_Local ]]; then
	if [ "${SRC_PROFILE}x" != "x" ] || [ "${SRC_REGION}x" != "x" ] || [ "${AMI_SRC_Local}x" != "x" ]; then
	Verify_AMI_Snapshot_KMS ${SRC_PROFILE} ${SRC_REGION} ${AMI_SRC_Local}
	else
	die "AMI_SRC_Local variable not set, check local copy of AMI with CCoE KMS Key"
	fi
fi

# Iterate over the snapshots, adding permissions for the destination account and copying
i=0
while read snapshotid; do
   ${SRC_STSEXEC} aws ec2 --region ${SRC_REGION} modify-snapshot-attribute --snapshot-id $snapshotid --attribute createVolumePermission --operation-type add --user-ids $DST_ACCT_ID || die "Unable to add permissions on the snapshots for the destination account. Aborting."
    echo -e "${COLOR}Permission added to Snapshot:${NC} ${snapshotid}"
    SRC_SNAPSHOT[$i]=${snapshotid}
		if [[ "${KMS_KEY_IDS}x" != "x"  ]] ; then 
		echo -e "${COLOR}Encrypted Snapshot Copy initiated for${NC} ${snapshotid}"
		echo "Test3: ${AMI_COPY_DSTKEY}"
		DST_SNAPSHOT[$i]=$(${DST_STSEXEC} aws ec2 copy-snapshot --region ${DST_REGION} --source-region ${SRC_REGION} --source-snapshot-id $snapshotid --description "Copied from $snapshotid" --encrypted ${CMK_OPT}  --query SnapshotId --output text|| die "Unable to copy snapshot. Aborting.")
		elif [[ "${CMK_ID}x" != "x" && "${KMS_KEY_IDS}x" = "x" ]]; then

			if [ "$(${DST_STSEXEC} aws --region ${DST_REGION}  kms describe-key --key-id ${CMK_ID} --query 'KeyMetadata.Enabled' --output text)" == "True" ]; then
        		CMK_OPT="--kms-key-id ${CMK_ID}"
        		echo -e "${COLOR}Validated destination KMS Key:${NC} ${CMK_ID}"
			echo -e "${COLOR}Non-Encrypted to Encrypted Snapshot Copy initiated for${NC} ${snapshotid}"
			DST_SNAPSHOT[$i]=$(${DST_STSEXEC} aws ec2 copy-snapshot --region ${DST_REGION} --source-region ${SRC_REGION} --source-snapshot-id $snapshotid --description "Copied from $snapshotid" --encrypted ${CMK_OPT}  --query SnapshotId --output text|| die "Unable to copy snapshot. Aborting.")
    			else
        		die "Provided Destination KMS Key ${CMK_ID} non existed, or in the wrong region, or not enabled. Aborting."
    			fi
		else
		echo "${COLOR}Non-Encrypted Snapshot Copy initiated for${NC} ${snapshotid}"
		DST_SNAPSHOT[$i]=$(${DST_STSEXEC} aws ec2 copy-snapshot --region ${DST_REGION} --source-region ${SRC_REGION} --source-snapshot-id $snapshotid --description "Copied from $snapshotid" --query SnapshotId --output text|| die "Unable to copy snapshot. Aborting.")	 
	 	fi

    i=$(( $i + 1 ))
    SIM_SNAP=$(${DST_STSEXEC} aws ec2 describe-snapshots --region ${DST_REGION} --filters Name=status,Values=pending --output text | wc -l)
    while [ $SIM_SNAP -ge 5 ]; do
        echo -e "${COLOR}Too many concurrent Snapshots, waiting...${NC}"
        sleep 30
        SIM_SNAP=$(${DST_STSEXEC} aws ec2 describe-snapshots --region ${DST_REGION} --filters Name=status,Values=pending --output text | wc -l)
    done

done <<< "$SNAPSHOT_IDS"

# Wait 1 second to avoid issues with eventual consistency
sleep 1

# Wait for EBS snapshots to be completed
echo -e "${COLOR}Waiting for all EBS Snapshots copies to complete. It may take a few minutes.${NC}"
i=0
while read snapshotid; do
    snapshot_progress="0%"
    snapshot_state=""
    while [ "$snapshot_progress" != "100%" ]; do
        snapshot_result=$(${DST_STSEXEC} aws ec2 describe-snapshots --region ${DST_REGION} \
                                                     --snapshot-ids ${DST_SNAPSHOT[i]} \
                                                     --no-paginate \
                                                     --query "Snapshots[*].[Progress, State]" \
                                                     --output text)
        snapshot_progress=$(echo $snapshot_result | awk '{print $1}')
        snapshot_state=$(echo $snapshot_result | awk '{print $2}')
        if [ "${snapshot_state}" == "error" ]; then
            die "Error copying snapshot"
        else
        echo -e "${COLOR} Snapshot progress: ${DST_SNAPSHOT[i]} $snapshot_progress"
        fi
        sleep 20
    done
  ${DST_STSEXEC} aws ec2 wait snapshot-completed --snapshot-ids ${DST_SNAPSHOT[i]} --region ${DST_REGION} || die "Failed while waiting the snapshots to be copied. Aborting."
    i=$(( $i + 1 ))
done <<< "$SNAPSHOT_IDS"
echo -e "${COLOR}EBS Snapshots copies completed ${NC}"

# Prepares the json data with the new snapshot IDs and remove unecessary information
sLen=${#SRC_SNAPSHOT[@]}

for (( i=0; i<${sLen}; i++)); do
    echo -e "${COLOR}Source Snapshots${NC} ${SRC_SNAPSHOT[i]} ${COLOR}copied as in Destination${NC} ${DST_SNAPSHOT[i]}"
    AMI_DETAILS=$(echo ${AMI_DETAILS} | sed -e s/${SRC_SNAPSHOT[i]}/${DST_SNAPSHOT[i]}/g )
done

# Copy AMI structure while removing read-only / non-idempotent values
NEW_AMI_DETAILS=$(echo ${AMI_DETAILS} | jq '.Name |= "Copy of " + . + " \(now)" | del(.. | .Encrypted?) | del(.Tags,.Platform,.ImageId,.CreationDate,.OwnerId,.ImageLocation,.State,.ImageType,.RootDeviceType,.Hypervisor,.Public,.EnaSupport )')

# Create the AMI in the destination
CREATED_AMI=$(${DST_STSEXEC} aws ec2 register-image --region ${DST_REGION} ${ENA_OPT} --cli-input-json "${NEW_AMI_DETAILS}" --query ImageId --output text || die "Unable to register AMI in the destination account. Aborting.")
echo -e "${COLOR}AMI created succesfully in the destination account:${NC} ${CREATED_AMI}"

# Copy Tags
if [ "${TAG_OPT}x" != "x" ]; then
    AMI_TAGS=$(echo ${AMI_DETAILS} | jq '.Tags')"}"
    NEW_AMI_TAGS="{\"Tags\":"$(echo ${AMI_TAGS} | tr -d ' ')
    $(${DST_STSEXEC} aws ec2 create-tags --resources ${CREATED_AMI} --cli-input-json ${NEW_AMI_TAGS} --region ${DST_REGION} || die "Unable to add tags to the AMI in the destination account. Aborting.")
    echo -e "${COLOR}Tags added sucessfully${NC}"
fi
