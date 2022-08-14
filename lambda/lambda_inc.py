import boto3

def lambda_handler(event, context):
    
    if context.function_name or __name__ == "__main__":
        table = boto3.resource('dynamodb').Table('resume-counter')

    counterID = 'resume'

    return inc_views(table, counterID)


def inc_views(table, counterID):
    # something wrong with this request
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