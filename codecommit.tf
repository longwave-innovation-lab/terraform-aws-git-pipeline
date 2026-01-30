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

data "aws_iam_policy_document" "start_pipeline" {
  count = var.is_codecommit ? 1 : 0
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
  count  = var.is_codecommit ? 1 : 0
  policy = data.aws_iam_policy_document.start_pipeline[0].json
}

resource "aws_iam_role" "codecommit_changes" {
  count              = var.is_codecommit ? 1 : 0
  name_prefix        = substr("${local.final_name}_Events", 0, 38)
  assume_role_policy = data.aws_iam_policy_document.event_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "start_pipeline" {
  count      = var.is_codecommit ? 1 : 0
  policy_arn = aws_iam_policy.start_pipeline[0].arn
  role       = aws_iam_role.codecommit_changes[0].name
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
  count     = var.is_codecommit ? 1 : 0
  target_id = "${local.final_name}_Trigger"
  arn       = aws_codepipeline.pipeline.arn
  role_arn  = aws_iam_role.codecommit_changes[0].arn
  rule      = aws_cloudwatch_event_rule.repo_changes[0].name
}
