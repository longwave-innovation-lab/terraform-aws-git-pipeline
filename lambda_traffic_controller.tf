# ---------------------------------------------------------------------------
# Monorepo Lambda Traffic Controller
#
# Created only when is_codecommit = true AND codepipeline_source_file_paths
# contains specific paths (not the catch-all ["*"]).
#
# Flow:
#   CodeCommit push
#     → EventBridge rule (repo_changes)
#       → THIS Lambda
#         → GetDifferences (CodeCommit)
#         → if any changed file matches the path filters
#           → StartPipelineExecution on this module's pipeline
# ---------------------------------------------------------------------------

# --- IAM Role ---------------------------------------------------------------

resource "aws_iam_role" "traffic_controller" {
  count       = local.use_lambda_trigger ? 1 : 0
  name_prefix = substr("${local.final_name}_TC", 0, 38)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "traffic_controller_basic_execution" {
  count      = local.use_lambda_trigger ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.traffic_controller[0].name
}

data "aws_iam_policy_document" "traffic_controller" {
  count = local.use_lambda_trigger ? 1 : 0

  statement {
    sid    = "AllowGetDifferences"
    effect = "Allow"
    actions = [
      "codecommit:GetDifferences",
    ]
    resources = [
      data.aws_codecommit_repository.source[0].arn
    ]
  }

  statement {
    sid    = "AllowStartPipelines"
    effect = "Allow"
    actions = [
      "codepipeline:StartPipelineExecution"
    ]
    resources = [
      aws_codepipeline.pipeline.arn
    ]
  }
}

resource "aws_iam_role_policy" "traffic_controller" {
  count  = local.use_lambda_trigger ? 1 : 0
  name   = "TrafficControllerPolicy"
  role   = aws_iam_role.traffic_controller[0].name
  policy = data.aws_iam_policy_document.traffic_controller[0].json
}

# --- Lambda Package ---------------------------------------------------------

data "archive_file" "traffic_controller" {
  count       = local.use_lambda_trigger ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/lambda_code/traffic_controller.py"
  output_path = "${path.module}/lambda_traffic_controller_payload.zip"
}

# --- Lambda Function --------------------------------------------------------

resource "aws_lambda_function" "traffic_controller" {
  count = local.use_lambda_trigger ? 1 : 0

  filename         = data.archive_file.traffic_controller[0].output_path
  function_name    = substr("${local.final_name}_TC", 0, 64)
  role             = aws_iam_role.traffic_controller[0].arn
  handler          = "traffic_controller.lambda_handler"
  description      = "Monorepo traffic controller for CodeCommit repo ${var.repo_name} branch ${var.repo_branch}"
  source_code_hash = data.archive_file.traffic_controller[0].output_base64sha256

  runtime       = "python3.13"
  architectures = ["arm64"]
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      # JSON-encoded list of path prefixes that gate whether to trigger the pipeline.
      FILE_PATH_FILTERS     = jsonencode(var.codepipeline_source_file_paths)
      DEFAULT_PIPELINE_NAME = aws_codepipeline.pipeline.name
      LOG_LEVEL             = "INFO"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.traffic_controller_basic_execution,
  ]
}

# --- EventBridge Permission -------------------------------------------------

resource "aws_lambda_permission" "traffic_controller_from_eventbridge" {
  count         = local.use_lambda_trigger ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.traffic_controller[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.repo_changes[0].arn
}
