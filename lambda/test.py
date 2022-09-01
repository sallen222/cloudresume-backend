import boto3
from moto import mock_dynamodb

from lambda_get import get_views
from lambda_inc import inc_views


def create_table(ddb=None):
    if not ddb:
        ddb = boto3.resource("dynamodb", endpoint_url="http://localhost:8000", region_name="us-east-1")

    tablename = "resume-counter"

    table = ddb.create_table(
        TableName=tablename,
        KeySchema=[
            {'AttributeName': 'CounterID', 'KeyType': 'HASH'},
        ],
        AttributeDefinitions=[
            {'AttributeName': 'CounterID', 'AttributeType': 'S'},
        ],
        BillingMode='PAY_PER_REQUEST',
    )

    # Wait until the table exists.
    table.meta.client.get_waiter("table_exists").wait(TableName=tablename)
    print(f"Created table {tablename}")

    return table


class TestApi:
    @classmethod
    def setup_class(cls):
        cls.mock_dynamodb = mock_dynamodb()
        cls.mock_dynamodb.start()
        cls.ddb = boto3.resource("dynamodb", region_name="us-east-1")
        cls.table = create_table(cls.ddb)

    @classmethod
    def teardown_class(cls):
        cls.table.delete()
        cls.ddb = None
        cls.mock_dynamodb.stop()

    def test_view_count(self):
                
        inc_views(TestApi.table, 'resume')
        test1 = get_views(TestApi.table, 'resume', True)
        print(test1)
        assert test1 == {
            "headers": {"Access-Control-Allow-Origin": "*"},
            "statusCode": 200,
            "body": "1"
        }
        inc_views(TestApi.table, 'resume')
        test2 = get_views(TestApi.table, 'resume', True)
        assert test2 == {
            "headers": {"Access-Control-Allow-Origin": "*"},
            "statusCode": 200,
            "body": "2"
        }
        test3 = get_views(TestApi.table, 'resume', False)
        assert test3 == {
            "headers": {"Access-Control-Allow-Origin": "*"},
            "statusCode": 200,
            "body": "validation error: check path and http method"
        }