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
        Action   = "logs:CreateLogGroup",
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Action   = "logs:CreateLogStream",
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Action   = "logs:PutLogEvents",
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Action   = "lambda:CreaeFunction",
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Action   = "lambda:DeleteFunction",
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

  # Optional: Define the S3 bucket trigger (uncomment if needed)
  # event_source {
  #   s3 {
  #     bucket = aws_s3_bucket.my_bucket.id
  #     events = ["s3:ObjectCreated:*"]
  #     filter_prefix = "my-folder/"
  #   }
  # }
}

# Output the ARN of the Lambda function for reference
output "lambda_function_arn" {
  value = aws_lambda_function.my_lambda.arn
}

# Output the name of the S3 bucket for reference
output "s3_bucket_name" {
  value = aws_s3_bucket.my_bucket.id
}
