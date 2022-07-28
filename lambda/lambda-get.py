import boto3
import json

table = boto3.resource('dynamodb').Table('resume-counter')

def lambda_handler(event, context):
    
    body = 'Provide counterID as a query parameter'

    print(event, json.dumps(event))
    print('queryStringParameters', json.dumps(event['queryStringParameters']))

    counterID = event.get("queryStringParameters").get("counterID")
    
    if (counterID
    and event.get('path') == '/counter'
    and event.get('httpMethod') == 'GET'
    ):
        body = table.get_item(Key={'CounterID': counterID})['Item']['viewcount'] if ('Item' in table.get_item(Key={'CounterID': counterID})) else 0
    
    return {
        "headers": {"Access-Control-Allow-Origin": "*"},
        "statusCode": 200,
        "body": f"{body}"
    }