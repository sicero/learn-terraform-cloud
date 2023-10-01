provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
  acl    = "private" # You can adjust the access control as needed
}

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

resource "aws_iam_role" "lambda_role" {
  name = "my-lambda-role"

  assume_role_policy = <<EOF
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
EOF
}


# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }

# resource "aws_instance" "ubuntu" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = var.instance_type

#   tags = {
#     Name = var.instance_name
#   }
# }
