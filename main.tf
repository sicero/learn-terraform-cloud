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
          "lambda:CreateFunction",
          "lambda:InvokeFunction",
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
      {
        Action   = [
          "cognito-idp:AdminCreateUser",
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
  acl    = "private"
}

# Create a DynamoDB table
resource "aws_dynamodb_table" "my_table" {
  name           = "MyTable"
  billing_mode   = "PAY_PER_REQUEST" # Change to your desired billing mode
  hash_key       = "MyPartitionKey"  # Change to your desired partition key attribute name
  read_capacity  = 5                  # Adjust read capacity units as needed
  write_capacity = 5                  # Adjust write capacity units as needed

  attribute {
    name = "MyPartitionKey"          # Change to your desired partition key attribute name
    type = "S"                       # Change to the appropriate data type
  }

  # You can add more attributes as needed
}

resource "aws_iam_policy" "dynamodb_policy" {
  name        = "DynamoDBPolicy"
  description = "IAM policy for DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:DescribeTable",
          "dynamodb:UpdateTable",
          "dynamodb:DeleteTable",
          "dynamodb:TagResoucre",
          "dynamodb:PutItem"
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}

resource "aws_iam_policy_attachment" "dynamodb_policy_attachment" {
  name        = "DynamoDBPolicyAttach"
  policy_arn = aws_iam_policy.dynamodb_policy.arn
  roles      = [aws_iam_role.lambda_role.name]  # Attach to your Lambda role
  # Alternatively, you can use "users" instead of "roles" if attaching to an IAM user.
}



# Create the Lambda function
resource "aws_lambda_function" "my_lambda" {
  filename      = "lambda_function.zip"
  function_name = "my-lambda-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"

  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      key1 = "value1",
      key2 = "value2",
    }
  }
}# Create an AWS Lambda function
resource "aws_lambda_function" "populate_dynamodb" {
  filename      = "lambda_deployment.zip"
  function_name = "populate-dynamodb-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"  # Use an appropriate Python runtime

  source_code_hash = filebase64sha256("lambda_deployment.zip")

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.my_table.name
    }
  }
}

# Create a CloudWatch Events Rule to trigger the Lambda function immediately
resource "aws_cloudwatch_event_rule" "trigger_lambda" {
  name        = "trigger-lambda-on-demand"
  description = "Trigger Lambda to populate DynamoDB"
  schedule_expression = "cron(0 0 * * ? *)"  # Trigger immediately and then every night
}

# Add a Lambda Permission to allow CloudWatch Events to invoke the Lambda function
resource "aws_lambda_permission" "allow_trigger_lambda" {
  statement_id  = "AllowExecutionFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.populate_dynamodb.function_name
  principal     = "events.amazonaws.com"
}

# Associate the CloudWatch Events Rule with the Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.trigger_lambda.name
  target_id = "trigger-lambda"
  arn       = aws_lambda_function.populate_dynamodb.arn
}


# Output the ARN of the Lambda function for reference
output "seed_cognito_" {
  value = aws_lambda_function.my_lambda.arn
}

# Output the name of the S3 bucket for reference
output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.id
}

# Output the name of the DynamoDB table for reference
output "dynamodb_table_name" {
  value = aws_dynamodb_table.my_table.name
}



# Create the Lambda function
resource "aws_lambda_function" "seed_cognito" {
  filename      = "seed_cognito_lambda_function.zip" # Path to your Lambda deployment package
  function_name = "seed-cognito-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x" # Change to your desired runtime

  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.my_user_pool.id # Use the User Pool ID from the module output
      COGNITO_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.my_user_pool_client.id
    }
  }
}

# Output the ARN of the Lambda function for reference
output "seed_cognito_lambda_function_arn" {
  value = aws_lambda_function.seed_cognito.arn
}

# Create a Cognito User Pool
resource "aws_cognito_user_pool" "my_user_pool" {
  name = "my-user-pool"
  # Configure other Cognito User Pool settings as needed
}

# Create a Cognito User Pool Client
resource "aws_cognito_user_pool_client" "my_user_pool_client" {
  name             = "my-user-pool-client"
  user_pool_id     = aws_cognito_user_pool.my_user_pool.id
  generate_secret  = false
  # Configure other Cognito User Pool Client settings as needed
}

# Output the User Pool ID and Client ID for reference
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.my_user_pool.id
}

output "user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.my_user_pool_client.id
}


# Create an AWS AppSync API
resource "aws_appsync_graphql_api" "my_appsync_api" {
  name          = "MyAppSyncAPI"
  authentication_type = "API_KEY"  # You can use other authentication types if needed

  schema = <<EOF
    type Query {
      getItem(id: ID!): MyItemType
      listItems: [MyItemType]
    }

    type Mutation {
      createItem(item: MyItemInput!): MyItemType
      updateItem(id: ID!, item: MyItemInput!): MyItemType
      deleteItem(id: ID!): MyItemType
    }

    input MyItemInput {
      # Define your input fields here
    }

    type MyItemType {
      # Define your output fields here
    }
  EOF
}

# Create an AWS AppSync data source for DynamoDB
resource "aws_appsync_datasource" "my_dynamodb_datasource" {
  api_id = aws_appsync_graphql_api.my_appsync_api.id
  name   = "MyDynamoDBDataSource"
  type   = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.my_table.name
    # You can specify region and other configurations here
  }
}

# Associate the data source with the AWS AppSync API
resource "aws_appsync_datasource_association" "my_dynamodb_association" {
  api_id        = aws_appsync_graphql_api.my_appsync_api.id
  data_source   = aws_appsync_datasource.my_dynamodb_datasource.name
}

# Create other resolvers for your GraphQL operations (listItems, createItem, updateItem, deleteItem)

# Output the AppSync API ID for reference
output "appsync_api_id" {
  value = aws_appsync_graphql_api.my_appsync_api.id
}

# Output the AppSync API key (or other authentication details) for reference
output "appsync_api_key" {
  value = aws_appsync_graphql_api.my_appsync_api.api_key
}