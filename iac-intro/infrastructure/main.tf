provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "random_pet" "lambda_bucket_name" {
  prefix = "sumanthyedoti"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_sqs_queue" "message_queue" {
  name = "sumanthyedoti-iac-queue"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../bin/funky"
  output_path = "../bin/funky.zip"
}

resource "aws_lambda_function" "funky" {
  function_name    = "sumanthyedoti-iac-func"
  filename         = data.archive_file.lambda_zip.output_path
  runtime          = "provided.al2023"
  handler          = "funky"
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  memory_size      = 128
  timeout          = 10

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.lambda_bucket.id
    }
  }
}

resource "aws_lambda_event_source_mapping" "funcky" {
  event_source_arn = aws_sqs_queue.message_queue.arn
  function_name    = aws_lambda_function.funky.arn
  batch_size       = 1
}
