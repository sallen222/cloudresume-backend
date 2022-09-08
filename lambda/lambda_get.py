import boto3

def lambda_handler(event, context):

    if context.function_name or __name__ == "__main__":
        table = boto3.resource('dynamodb').Table('resume-counter')

    counterID = event.get("queryStringParameters").get("counterID")

    if (event.get('path') == '/counter'
    and event.get('httpMethod') == 'GET'
    ): queryparamExists = True
    else: queryparamExists = False
    return get_views(table, counterID, queryparamExists)

def get_views(table, counterID, queryparamExists):
    
    body = 'Provide CounterID as a query parameter'

    if (counterID and queryparamExists):
        body = table.get_item(Key={'CounterID': counterID})['Item']['viewcount'] if ('Item' in table.get_item(Key={'CounterID': counterID})) else 0
    
        return {
            "headers": {"Access-Control-Allow-Origin": "https://sallen.me"},
            "statusCode": 200,
            "body": f"{body}"
        }
    else: return {
        "headers": {"Access-Control-Allow-Origin": "https://sallen.me"},
        "statusCode": 200,
        "body": "validation error: check path and http method"
    }