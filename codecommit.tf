data "aws_codecommit_repository" "source" {
  count           = var.is_codecommit ? 1 : 0
  repository_name = var.repo_name
}

# Creating eventbridge to avoid polling for changes
data "aws_iam_policy_document" "event_assume_role" {
  count = var.is_codecommit ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Direct-mode only: EventBridge role is allowed to call StartPipelineExecution.
# In Lambda-traffic-controller mode this permission is not needed on the EventBridge role
# (the Lambda itself carries the StartPipelineExecution permission).
data "aws_iam_policy_document" "start_pipeline" {
  count = var.is_codecommit && !local.use_lambda_trigger ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "codepipeline:StartPipelineExecution"
    ]
    resources = [
      aws_codepipeline.pipeline.arn
    ]
  }
}

resource "aws_iam_policy" "start_pipeline" {
  count  = var.is_codecommit && !local.use_lambda_trigger ? 1 : 0
  policy = data.aws_iam_policy_document.start_pipeline[0].json
}

resource "aws_iam_role" "codecommit_changes" {
  count              = var.is_codecommit ? 1 : 0
  name_prefix        = substr("${local.final_name}_Events", 0, 38)
  assume_role_policy = data.aws_iam_policy_document.event_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "start_pipeline" {
  count      = var.is_codecommit && !local.use_lambda_trigger ? 1 : 0
  policy_arn = aws_iam_policy.start_pipeline[0].arn
  role       = aws_iam_role.codecommit_changes[0].name
}

# Lambda-traffic-controller mode: EventBridge role needs InvokeFunction instead.
data "aws_iam_policy_document" "invoke_traffic_controller" {
  count = local.use_lambda_trigger ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.traffic_controller[0].arn
    ]
  }
}

resource "aws_iam_role_policy" "invoke_traffic_controller" {
  count  = local.use_lambda_trigger ? 1 : 0
  name   = "InvokeTrafficController"
  role   = aws_iam_role.codecommit_changes[0].name
  policy = data.aws_iam_policy_document.invoke_traffic_controller[0].json
}

resource "aws_cloudwatch_event_rule" "repo_changes" {
  count       = var.is_codecommit ? 1 : 0
  name_prefix = substr("${local.final_name}_Events", 0, 38)
  role_arn    = aws_iam_role.codecommit_changes[0].arn
  description = <<-EOT
Event to start the pipeline <${aws_codepipeline.pipeline.name}>
when codecommit repository <${data.aws_codecommit_repository.source[0].repository_name}>
changes on branch <${var.repo_branch}>
EOT
  event_pattern = jsonencode({
    source : [
      "aws.codecommit"
    ],
    detail-type : [
      "CodeCommit Repository State Change"
    ],
    resources : [
      data.aws_codecommit_repository.source[0].arn
    ],
    detail : {
      referenceType : [
        "branch"
      ],
      referenceName : [
        var.repo_branch
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger" {
  # Direct mode: EventBridge fires the pipeline directly.
  count     = var.is_codecommit && !local.use_lambda_trigger ? 1 : 0
  target_id = "${local.final_name}_Trigger"
  arn       = aws_codepipeline.pipeline.arn
  role_arn  = aws_iam_role.codecommit_changes[0].arn
  rule      = aws_cloudwatch_event_rule.repo_changes[0].name
}

# Lambda-traffic-controller mode: EventBridge routes to the Lambda instead.
resource "aws_cloudwatch_event_target" "traffic_controller_trigger" {
  count     = local.use_lambda_trigger ? 1 : 0
  target_id = "${local.final_name}_TCTrigger"
  arn       = aws_lambda_function.traffic_controller[0].arn
  role_arn  = aws_iam_role.codecommit_changes[0].arn
  rule      = aws_cloudwatch_event_rule.repo_changes[0].name

  retry_policy {
    maximum_retry_attempts       = 3
    maximum_event_age_in_seconds = 60
  }
}
