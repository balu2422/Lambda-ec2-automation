resource "aws_instance" "ec2_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name = "TestEC2Instance"
  }
}

resource "aws_lambda_function" "start_lambda" {
  function_name = "start-ec2-lambda"
  filename      = "app_start.zip"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app_start.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_lambda_function" "stop_lambda" {
  function_name = "stop-ec2-lambda"
  filename      = "app_stop.zip"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app_stop.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_cloudwatch_event_rule" "start_ec2_rule" {
  name                = "start-ec2-instance"
  schedule_expression = "cron(0 8 * * ? *)"  # Every day at 8 AM
}

resource "aws_cloudwatch_event_rule" "stop_ec2_rule" {
  name                = "stop-ec2-instance"
  schedule_expression = "cron(0 17 * * ? *)"  # Every day at 5 PM
}

resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_ec2_rule.name
  target_id = "start-ec2-lambda"
  arn       = aws_lambda_function.start_lambda.arn
}

resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_ec2_rule.name
  target_id = "stop-ec2-lambda"
  arn       = aws_lambda_function.stop_lambda.arn
}

resource "aws_lambda_permission" "start_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_lambda.function_name
  principal     = "events.amazonaws.com"
  statement_id  = "AllowExecutionFromCloudWatch"
}

resource "aws_lambda_permission" "stop_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_lambda.function_name
  principal     = "events.amazonaws.com"
  statement_id  = "AllowExecutionFromCloudWatch"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect    = "Allow",
        Sid       = ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_ec2_policy" {
  name = "lambda-ec2-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["ec2:StartInstances", "ec2:StopInstances"],
        Resource = "*",
        Effect   = "Allow"
      }
    ]
  })
}

output "instance_id" {
  value = aws_instance.ec2_instance.id
}
