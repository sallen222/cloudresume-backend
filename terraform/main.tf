provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Application = "cloud-resume"
    }
  }
}

#Start Dynamodb

resource "aws_dynamodb_table" "resume-db" {
  name         = "resume-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "CounterID"

  attribute {
    name = "CounterID"
    type = "S"
  }
}

#End Dynamodb Start APIGW

resource "aws_api_gateway_rest_api" "resume-api" {
  name = "resume-counter-api"
}

resource "aws_api_gateway_resource" "resume-resource" {
  rest_api_id = aws_api_gateway_rest_api.resume-api.id
  parent_id   = aws_api_gateway_rest_api.resume-api.root_resource_id
  path_part   = "counter"
}

resource "aws_api_gateway_method" "counter-method" {
  rest_api_id   = aws_api_gateway_rest_api.resume-api.id
  resource_id   = aws_api_gateway_resource.resume-resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "counter-method-inc" {
  rest_api_id   = aws_api_gateway_rest_api.resume-api.id
  resource_id   = aws_api_gateway_resource.resume-resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "apigw-integration-get" {
  rest_api_id             = aws_api_gateway_rest_api.resume-api.id
  resource_id             = aws_api_gateway_resource.resume-resource.id
  http_method             = aws_api_gateway_method.counter-method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  #invoke arn of lambda function
  uri = aws_lambda_function.get.invoke_arn
}

resource "aws_api_gateway_integration" "apigw-integration-inc" {
  rest_api_id             = aws_api_gateway_rest_api.resume-api.id
  resource_id             = aws_api_gateway_resource.resume-resource.id
  http_method             = aws_api_gateway_method.counter-method-inc.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  #invoke arn of lambda function
  uri = aws_lambda_function.inc.invoke_arn
}

resource "aws_api_gateway_deployment" "resume-deployment" {
  rest_api_id = aws_api_gateway_rest_api.resume-api.id

  depends_on = [
    aws_api_gateway_integration.apigw-integration-get,
    aws_api_gateway_integration.apigw-integration-inc
  ]
}

# https://github.com/squidfunk/terraform-aws-api-gateway-enable-cors
resource "aws_api_gateway_stage" "resume-stage" {
  deployment_id = aws_api_gateway_deployment.resume-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.resume-api.id
  stage_name    = "counter"
}

#End APIGW Start Lambda

data "archive_file" "lambda-get" {
  type        = "zip"
  source_file = "../lambda/lambda-get.py"
  output_path = "lambda-get.zip"
}

resource "aws_lambda_permission" "apigw-lambda-get" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume-api.execution_arn}/*/*/${aws_api_gateway_resource.resume-resource.path_part}"
}

resource "aws_lambda_function" "get" {
  filename      = "lambda-get.zip"
  function_name = "resume-get"
  role          = aws_iam_role.lambda-role-get.arn
  handler       = "lambda-get.lambda_handler"
  runtime       = "python3.9"

  source_code_hash = data.archive_file.lambda-get.output_base64sha256

  depends_on = [
    data.archive_file.lambda-get
  ]
}

data "archive_file" "lambda-inc" {
  type        = "zip"
  source_file = "../lambda/lambda-inc.py"
  output_path = "lambda-inc.zip"
}

resource "aws_lambda_permission" "apigw-lambda-inc" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inc.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume-api.execution_arn}/*/*/${aws_api_gateway_resource.resume-resource.path_part}"
}

resource "aws_lambda_function" "inc" {
  filename      = "lambda-inc.zip"
  function_name = "resume-inc"
  role          = aws_iam_role.lambda-role-inc.arn
  handler       = "lambda-inc.lambda_handler"
  runtime       = "python3.9"

  source_code_hash = data.archive_file.lambda-get.output_base64sha256

  depends_on = [
    data.archive_file.lambda-inc
  ]
}

#End Lambda Start IAM

resource "aws_iam_role" "lambda-role-get" {
  name = "lambda-role-get"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role" "lambda-role-inc" {
  name = "lambda-role-inc"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role" "apigw-role" {
  name = "apigw-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "lambda-dynamodb-policy-get" {
  name        = "resume-lambda-dynamodb-policy-get"
  description = "Lets lambda-role manage dynamodb."
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem"
      ],
      "Resource": "${aws_dynamodb_table.resume-db.arn}",
      "Effect": "Allow",
      "Sid": "AllowReadDynamoDb"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "lambda-dynamodb-policy-inc" {
  name        = "resume-lambda-dynamodb-policy-inc"
  description = "Lets lambda-role manage dynamodb."
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem"
      ],
      "Resource": "${aws_dynamodb_table.resume-db.arn}",
      "Effect": "Allow",
      "Sid": "AllowReadandWriteDynamoDb"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda-dynamodb-attach-get" {
  role       = aws_iam_role.lambda-role-get.name
  policy_arn = aws_iam_policy.lambda-dynamodb-policy-get.arn
}

resource "aws_iam_role_policy_attachment" "lambda-dynamodb-attach-inc" {
  role       = aws_iam_role.lambda-role-inc.name
  policy_arn = aws_iam_policy.lambda-dynamodb-policy-inc.arn
}