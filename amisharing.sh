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
    -d,               AWS CLI profile name for AMI destination account.
    -a,               ID of AMI to be copied, Source AMI ID.
    -r,               Destination region for copied AMI.
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


# Checking dependencies
command -v jq >/dev/null 2>&1 || die "jq is required but not installed. Aborting. See https://stedolan.github.io/jq/download/"
command -v aws >/dev/null 2>&1 || die "aws cli is required but not installed. Aborting. See https://docs.aws.amazon.com/cli/latest/userguide/installing.html"



while getopts ":d:a:r:" opt; do
    case $opt in
        h) usage && exit 1
        ;;
#        s) SRC_PROFILE="$OPTARG"
#        ;;
        d) DST_PROFILE="$OPTARG"
        ;;
        a) AMI_ID="$OPTARG"
        ;;
#        l) SRC_REGION="$OPTARG"
#        ;;
        r) DST_REGION="$OPTARG"
        ;;
#        k) CMK_ID="$OPTARG"
#        ;;
#        n) ENA_OPT="--ena-support"
#        ;;
#        t) TAG_OPT="y"
#        ;;
        \?) echo "Invalid option -$OPTARG" >&2
        ;;
    esac
done


#Added on 25July- For Jenkins Jon Role based authentication
#SRC_PROFILE Always devops account where we are going to keep AMI Repo.
SRC_PROFILE="986148801171"
SRC_REGION="${DST_REGION}"

MBA_ROLEARN="arn:aws:iam::356083436205:role/DevOps-Automation"
SRC_ROLEARN="arn:aws:iam::$SRC_PROFILE:role/HPE-Cloud-Governance-Parent-Account-Access-Role"
DST_ROLEARN="arn:aws:iam::$DST_PROFILE:role/HPE-Cloud-Governance-Parent-Account-Access-Role"

SRC_STSEXEC="stsexec --rolearn $MBA_ROLEARN --rolearn $SRC_ROLEARN"
DST_STSEXEC="stsexec --rolearn $MBA_ROLEARN --rolearn $DST_ROLEARN"


# Validating Input parameters
if [ "${SRC_PROFILE}x" == "x" ] || [ "${DST_PROFILE}x" == "x" ] || [ "${AMI_ID}x" == "x" ] || [ "${DST_REGION}x" == "x" ]; then
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

# Describes the source AMI and stores its contents
AMI_DETAILS=$(${SRC_STSEXEC} aws ec2 describe-images --region ${SRC_REGION} --image-id ${AMI_ID}  --query 'Images[0]'| jq 'del (.ProductCodes)'|| die "Unable to describe the AMI in the source account. Aborting.")
# Retrieve the snapshots and key ID's
SNAPSHOT_IDS=$(echo ${AMI_DETAILS} | jq -r '.BlockDeviceMappings[] | select(has("Ebs")) | .Ebs.SnapshotId' || die "Unable to get the encrypted snapshot ids from AMI. Aborting.")
echo -e "${COLOR}Snapshots found:${NC}" ${SNAPSHOT_IDS}

KMS_KEY_IDS=$(${SRC_STSEXEC} aws ec2 describe-snapshots --region ${SRC_REGION}  --snapshot-ids ${SNAPSHOT_IDS} --query 'Snapshots[?Encrypted==`true`]' | jq -r '[.[].KmsKeyId] | unique | .[]' || die "Unable to get KMS Key Ids from the snapshots. Aborting.")



#
if [ "${KMS_KEY_IDS}x" != "x" ] ; then
  echo -e "${COLOR}Customer managed KMS key(s) used on source AMI:${NC}" ${KMS_KEY_IDS}
  # Iterate over the Keys and create the Grants
  while read key; do
      KEY_MANAGER=$(${SRC_STSEXEC} aws kms describe-key --key-id ${key} --query "KeyMetadata.KeyManager" --region ${SRC_REGION} --output text || die "Unable to retrieve the Key Manager information. Aborting.")
      if [ "${KEY_MANAGER}" == "AWS" ] ; then

  die "${COLOR} The Default AWS/EBS key is being used by the snapshot. Unable to proceed.${NC}"
      fi
     ${SRC_STSEXEC} aws kms --region ${SRC_REGION} create-grant --key-id $key --grantee-principal $DST_ACCT_ID --operations DescribeKey Decrypt CreateGrant > /dev/null || die "Unable to create a KMS grant for the destination account. Aborting."
      echo -e "${COLOR}Grant created for:${NC}" ${key}
  done <<< "${KMS_KEY_IDS}"
else
  echo -e "${COLOR}No encrypted EBS Volumes were found in the source AMI!${NC}"
fi

#Share AMI and CMK key to another account

SHARE_AMI=$(${SRC_STSEXEC} aws ec2 modify-image-attribute --region ${SRC_REGION} --image-id ${AMI_ID} --launch-permission "Add=[{UserId=${DST_PROFILE}}]" || die "Unable to add permission to ${DST_PROFILE} to share AMI ${AMI_ID}")

echo "AMI ${AMI_ID} is shared with ${DST_PROFILE} Successfully "
