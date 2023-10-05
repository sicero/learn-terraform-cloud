# output "instance_ami" {
#   value = aws_instance.ubuntu.ami
# }

# output "instance_arn" {
#   value = aws_instance.ubuntu.arn
# }

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
