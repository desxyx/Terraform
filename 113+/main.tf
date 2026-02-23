# terraform {
#   required_version = ">= 1.5.0"
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 5.0"
#     }
#     random = {
#       source  = "hashicorp/random"
#       version = ">= 3.0"
#     }
#     archive = {
#       source  = "hashicorp/archive"
#       version = ">= 2.0"
#     }
#   }
# }

# provider "aws" {
#   region = "us-east-1"
# }

# # ---- package lambda code into a zip ----
# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_dir  = "${path.module}/lambda"
#   output_path = "${path.module}/lambda.zip"
# }

# # ---- unique suffix for S3 bucket name ----
# resource "random_id" "suffix" {
#   byte_length = 4
# }

# resource "aws_s3_bucket" "lambda_artifacts" {
#   bucket        = "desx-lambda-artifacts-${random_id.suffix.hex}"
#   force_destroy = true
# }

# resource "aws_s3_object" "lambda_zip" {
#   bucket = aws_s3_bucket.lambda_artifacts.id
#   key    = "lambda/hello/lambda.zip"
#   source = data.archive_file.lambda_zip.output_path
#   etag   = filemd5(data.archive_file.lambda_zip.output_path)
# }

# # ---- IAM role for Lambda ----
# resource "aws_iam_role" "lambda_role" {
#   name = "desx-hello-lambda-role-${random_id.suffix.hex}"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Principal = { Service = "lambda.amazonaws.com" }
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "basic_logs" {
#   role       = aws_iam_role.lambda_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# # ---- Lambda function ----
# resource "aws_lambda_function" "hello" {
#   function_name = "desx-hello-${random_id.suffix.hex}"
#   role          = aws_iam_role.lambda_role.arn
#   handler       = "index.handler"
#   runtime       = "nodejs20.x"

#   s3_bucket = aws_s3_bucket.lambda_artifacts.id
#   s3_key    = aws_s3_object.lambda_zip.key

#   timeout = 5
#   memory_size = 128
# }

# # ---- Function URL (public) ----
# resource "aws_lambda_function_url" "hello_url" {
#   function_name      = aws_lambda_function.hello.function_name
#   authorization_type = "NONE"
# }

# resource "aws_lambda_permission" "allow_public_url" {
#   statement_id  = "AllowPublicFunctionUrl"
#   action        = "lambda:InvokeFunctionUrl"
#   function_name = aws_lambda_function.hello.function_name
#   principal     = "*"
#   function_url_auth_type = "NONE"
# }

# output "hello_url" {
#   value = aws_lambda_function_url.hello_url.function_url
# }
