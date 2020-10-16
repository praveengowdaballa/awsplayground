import os
import boto3
import subprocess
import argparse

parser = argparse.ArgumentParser(description="Print region Number")
parser.add_argument("-r", "--region", metavar= "", help = "Pass the Region", required = True)
parser.add_argument("-a", "--account", metavar= "", help = "Pass the Account ID", required = True)

args = parser.parse_args()

account = args.account.split(",")
region = args.region.split(",")

VPC="aws ec2 describe-vpcs  --query 'Vpcs[].{CIDR:CidrBlock,VPCID:VpcId,Name:Tags[?Key==`Name`].Value[] | [0]}' --profile " + args.account + " --region " + args.region + " --output table"
os.system(VPC)


Subnet="aws ec2 describe-subnets --query 'Subnets[].{CIDR:CidrBlock,SubnetID:SubnetId,VPCID:VpcId,AZ:AvailabilityZone,Name:Tags[?Key==`Name`].Value[] | [0]}' --profile " + args.account + " --region " + args.region + " --output table"
os.system(Subnet)

Peering="aws ec2 describe-vpc-peering-connections --query 'VpcPeeringConnections[].{AcceptorVPCCIDR:AccepterVpcInfo.CidrBlock,AccepterAccount:AccepterVpcInfo.OwnerId,AcceptorVPCID:AccepterVpcInfo.VpcId,RequestorVPCCIDR:RequesterVpcInfo.CidrBlock,RequestorAccount:RequesterVpcInfo.OwnerId,RequestorVPCID:RequesterVpcInfo.VpcId}' --profile " + args.account + " --region " + args.region + " --output table"
os.system(Peering)

Route="aws ec2 describe-route-tables  --query 'RouteTables[].{RouteTableID:RouteTableId,VPCID:VpcId,Name:Tags[?Key==`Name`].Value[] | [0]}' --profile " + args.account + " --region " + args.region + " --output table"
os.system(Route)

SG="aws ec2 describe-security-groups  --query 'SecurityGroups[].{SGID:GroupId,VPCID:VpcId,GroupName:GroupName,NameofSG:Tags[?Key==`Name`].Value[] | [0]}' --output table  --profile " + args.account + " --region " + args.region + " | grep -v launch-wizard"
os.system(SG)

dhcp="aws ec2 describe-dhcp-options  --query 'DhcpOptions[].{DhcpID:DhcpOptionsId,Name:Tags[?Key==`Name`].Value[] | [0]}' --profile " + args.account + " --region " + args.region + " --output table"
os.system(dhcp)

NACL="aws ec2 describe-network-acls  --query 'NetworkAcls[].{ACLID:NetworkAclId,VPCID:VpcId}'  --profile " + args.account + " --region " + args.region + " --output table"
os.system(NACL)

EIP="aws ec2 describe-addresses --query 'Addresses[].{Domain:Domain,NetworkInterfaceId:NetworkInterfaceId,PublicIP:PublicIp,PrivateIP:PrivateIpAddress,Name:Tags[?Key==`Name`].Value[] | [0]}' --profile " + args.account + " --region " + args.region + " --output table"
os.system(EIP)

IGW="aws ec2 describe-internet-gateways --query 'InternetGateways[].{ID:InternetGatewayId,State:Attachments[0].State,VPCID:Attachments[0].VpcId,Name:Tags[?Key==`Name`].Value[] | [0]}' --profile " + args.account + " --region " + args.region + " --output table"
os.system(IGW)

VPCEndpoint="aws ec2 describe-vpc-endpoints --query 'VpcEndpoints[].{ServiceName:ServiceName,VpcEndpointType:VpcEndpointType,VpcId:VpcId,GroupID:Groups[0].GroupId,GroupName:Groups[0].GroupName,SubnetID:SubnetIds[0],Name:Tags[?Key==`Name`].Value[] | [0]}' --profile " + args.account + " --region " + args.region + " --output table"
os.system(VPCEndpoint)

VGW="aws directconnect describe-virtual-gateways --query 'virtualGateways[].{VGID:virtualGatewayId,State:virtualGatewayState,Name:Tags[?Key==`Name`].Value[] | [0]}'  --profile " + args.account + " --region " + args.region + " --output table"
os.system(VGW)

CGW="aws ec2 describe-customer-gateways --query 'CustomerGateways[].{IP:IpAddress,State:State,CustomerGatewayId:CustomerGatewayId,BgpASN:BgpAsn,Name:Tags[?Key==`Name`].Value[] | [0]}'  --profile " + args.account + " --region " + args.region + " --output table"
os.system(CGW)

VPN="aws ec2 describe-vpn-connections  --query 'VpnConnections[].{VPNID:VpnConnectionId,VGWID:VpnGatewayId,CGWID:CustomerGatewayId,State:State,Name:Tags[?Key==`Name`].Value[] | [0]}'  --profile " + args.account + " --region " + args.region + " --output table"
os.system(VPN)


EC2="aws ec2 describe-instances --query 'Reservations[].Instances[].{AZ:Placement.AvailabilityZone, State:State.Name, ID:InstanceId,Type:InstanceType,Name:Tags[?Key==`Name`].Value[] | [0]}' --profile " + args.account + " --region " + args.region + " --output table"
os.system(EC2)


LoadB="aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].{LoadBalancerName:LoadBalancerName,VPCID:VPCId}'  --profile " + args.account + " --region " + args.region + " --output table"
os.system(LoadB)


ASG="aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].{LaunchConfigurationName:LaunchConfigurationName,AutoScalingGroupName:AutoScalingGroupName,VPCZoneIdentifier:VPCZoneIdentifier}' --profile " + args.account + " --region " + args.region + " --output table"
os.system(ASG)
