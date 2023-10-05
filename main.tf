# Define the provider (AWS in this case)
provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
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

# Define a resolver for the query
resource "aws_appsync_resolver" "my_resolver" {
  api_id                  = aws_appsync_graphql_api.my_appsync_api.id
  type_name               = "Query"
  field_name              = "myQuery"  # Replace with your query name
  data_source             = "AWS_LAMBDA"  # Data source type

  request_mapping_template = <<EOF
{
    "version": "2018-05-29",
    "operation": "Invoke",
    "payload": {
        "field": "myQuery"
    }
}
EOF

  response_mapping_template = <<EOF
$util.toJson($ctx.result)
EOF
}

# Output the GraphQL API endpoint
output "appsync_api_endpoint" {
  value = aws_appsync_graphql_api.my_appsync_api.uris[0]
}
