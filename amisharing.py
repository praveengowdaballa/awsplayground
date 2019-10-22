import boto3
import argparse


dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('AMI_Sharing')

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--AMI_ID", help="Sharing Ami id")
parser.add_argument("-a", "--Destination_Account", help="Destination Account")
parser.add_argument("-r", "--Destination_Region", help="Destination Region")
parser.add_argument("-g", "--Product_Group_Name", help="Product Group Name")
parser.add_argument("-n", "--Requester_Name", help="Requester Name")
parser.add_argument("-m", "--Requester_Mail_ID", help="Requester_Mail_ID")
args = parser.parse_args()


details = {
    "AMI_ID" : args.AMI_ID,
    "Destination_Account" : int(args.Destination_Account),
    "Destination_Region" : args.Destination_Region,
    "Product_Group_Name" : args.Product_Group_Name,
    "Requester_Name" : args.Requester_Name,
    "Requester_Mail_ID" : args.Requester_Mail_ID
    }
response = table.put_item(Item=details)
