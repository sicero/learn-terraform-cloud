# Define the provider (AWS in this case)
provider "aws" {
  region = "eu-west-2" # Change to your desired AWS region
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "my-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM policy for the Lambda function
resource "aws_iam_policy" "lambda_policy" {
  name        = "LambdaPolicy"
  description = "IAM policy for Lambda function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "lambda:CreateFunction",  # Add this permission
          "lambda:InvokeFunction",   # Include other Lambda permissions as needed
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:UpdateFunctionConfiguration",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}

# Attach the Lambda policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "sicero-landing-zone-1"
  acl    = "private" # You can adjust the access control as needed
}

# Create the Lambda function
resource "aws_lambda_function" "my_lambda" {
  filename      = "lambda_function.zip" # Path to your Lambda deployment package
  function_name = "my-lambda-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x" # Change to your desired runtime

  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      key1 = "value1",
      key2 = "value2",
    }
  }
}


# Define the AWS AppSync GraphQL API
resource "aws_appsync_graphql_api" "my_appsync_api" {
  authentication_type = "API_KEY" # Change as needed (API_KEY, AWS_IAM, OPENID_CONNECT, AMAZON_COGNITO_USER_POOLS)
  name                = "my-graphql-api"
}

# Create an API Key for the AppSync API (only for API_KEY authentication)
resource "aws_appsync_api_key" "my_api_key" {
  api_id = aws_appsync_graphql_api.my_appsync_api.id
}

# Define a GraphQL schema for the AppSync API (replace with your schema)
resource "aws_appsync_datasource" "my_datasource" {
  api_id          = aws_appsync_graphql_api.my_appsync_api.id
  name            = "MyDataSource"
  type            = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.lambda_role.arn
  function_arn    = aws_lambda_function.my_lambda.arn # Corrected attribute name
}

resource "aws_appsync_resolver" "my_resolver" {
  api_id                  = aws_appsync_graphql_api.my_appsync_api.id
  type_name               = "Query"
  field_name              = "myQuery"  # Replace with your query name
  data_source             = aws_appsync_datasource.my_datasource.name
  request_template        = <<EOF
  {
      "version": "2018-05-29",
      "operation": "Invoke",
      "payload": {
          "field": "myQuery"
      }
  }
EOF

  response_template       = <<EOF
  $util.toJson($ctx.result)
EOF
}

# Output the GraphQL API endpoint
output "appsync_api_endpoint" {
  value = aws_appsync_graphql_api.my_appsync_api.uris[0]
}

# Output the ARN of the Lambda function for reference
output "lambda_function_arn" {
  value = aws_lambda_function.my_lambda.arn
}

# Output the name of the S3 bucket for reference
output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.id
}
