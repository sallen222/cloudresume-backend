import boto3
import json

table = boto3.resource('dynamodb').Table('resume-counter')

def lambda_handler(event, context):
    
    counterID = 'resume'

    print(event, json.dumps(event))
    print('queryStringParameters', json.dumps(event['queryStringParameters']))

    if counterID:
        output = table.get_item(Key={"CounterID": counterID})
    
        if 'Item' in output:
            table.update_item(
                Key={"CounterID": counterID},
                UpdateExpression="SET viewcount = viewcount + :inc",
                ExpressionAttributeValues={":inc": 1},
            )
        else:
            table.put_item(Item={"CounterID": counterID, "viewcount":1})
        
        body = table.get_item(Key={"CounterID": counterID})

    return {
        "headers": {"Access-Control-Allow-Origin": "*"},
        "statusCode": 200,
        "body": f"{body}"
    }