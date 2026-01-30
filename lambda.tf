resource "aws_iam_role" "lambda_function_role" {
  name_prefix = substr("${local.final_name}${local.pipeline_resources_suffix}", 0, 37)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_function_role.name
}

data "aws_iam_policy_document" "lambda_function_policy_document" {

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds"
    ]
    resources = local.codebuild_projects_arns
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [aws_sns_topic.pipeline_notifications.arn]
  }
}

resource "aws_iam_role_policy" "codebuild_describe" {
  role   = aws_iam_role.lambda_function_role.name
  policy = data.aws_iam_policy_document.lambda_function_policy_document.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_code/app.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

resource "aws_lambda_function" "codebuild_event_listener" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename         = "${path.module}/lambda_function_payload.zip"
  function_name    = substr("${local.final_name}${local.pipeline_resources_suffix}", 0, 64)
  role             = aws_iam_role.lambda_function_role.arn
  handler          = "app.lambda_handler"
  description      = "Lambda that will react to events from ${aws_codepipeline.pipeline.name} for repo ${var.repo_owner}/${var.repo_name} branch ${var.repo_branch}"
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime       = "python3.13"
  architectures = ["arm64"]
  timeout       = 10
  memory_size   = 256
  environment {
    variables = {
      "SNS_TOPIC_ARN" = aws_sns_topic.pipeline_notifications.arn
    }
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.codebuild_event_listener.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.codebuild_events_rule.arn
}
