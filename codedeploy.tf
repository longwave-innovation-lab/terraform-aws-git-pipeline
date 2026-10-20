# ---------------------------------------------------------------------------
# Optional CodeDeploy stage — supporting resources
#
# Created only when var.codedeploy_config is set (see codepipeline.tf for the
# stage itself). The CodeDeploy application and deployment group are owned by
# the caller: this module only needs their names.
#
# Flow:
#   Build (CodeBuild, output "build_output")
#     → Deploy (CodeDeploy, revision = build_output zip in the artifact bucket)
#       → EventBridge "CodePipeline Stage Execution State Change" (stage Deploy)
#         → SNS topic of this pipeline (same subscribers of the build notifications)
#
# Why EventBridge → SNS and not the existing notifier Lambda: the Lambda parses
# CodeBuild events only, deploy outcomes would otherwise go unnoticed.
# ---------------------------------------------------------------------------

locals {
  codedeploy_application_arn = (
    local.codedeploy_enabled ?
    "arn:aws:codedeploy:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:application:${var.codedeploy_config.application_name}" :
    ""
  )
  codedeploy_deployment_group_arn = (
    local.codedeploy_enabled ?
    "arn:aws:codedeploy:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${var.codedeploy_config.application_name}/${var.codedeploy_config.deployment_group_name}" :
    ""
  )
}

# --- IAM: CodePipeline role -> CodeDeploy ----------------------------------
# Permission set required by the CodeDeploy action, as documented in
# https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodeDeploy.html
# scoped to the single application / deployment group passed by the caller.

data "aws_iam_policy_document" "codepipeline_codedeploy" {
  count = local.codedeploy_enabled ? 1 : 0

  statement {
    sid    = "CodeDeployDeployment"
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetDeployment",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:ListDeployments",
      "codedeploy:ListDeploymentGroups",
      "codedeploy:GetDeploymentGroup"
    ]
    resources = [
      local.codedeploy_application_arn,
      local.codedeploy_deployment_group_arn
    ]
  }

  # The deployment configuration is chosen on the deployment group (caller side)
  # and is not known by this module: read-only access to any configuration.
  statement {
    sid       = "CodeDeployReadDeploymentConfig"
    effect    = "Allow"
    actions   = ["codedeploy:GetDeploymentConfig"]
    resources = ["arn:aws:codedeploy:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"]
  }

  # List API without resource-level permissions
  statement {
    sid       = "CodeDeployListDeploymentConfigs"
    effect    = "Allow"
    actions   = ["codedeploy:ListDeploymentConfigs"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_codedeploy" {
  count  = local.codedeploy_enabled ? 1 : 0
  policy = data.aws_iam_policy_document.codepipeline_codedeploy[0].json
  role   = aws_iam_role.codepipeline_role.name
}

# --- Notifications: Deploy stage state -> SNS ------------------------------

resource "aws_cloudwatch_event_rule" "codedeploy_stage_events" {
  count       = local.codedeploy_notifications_enabled ? 1 : 0
  name_prefix = substr("${local.final_name}_Deploy", 0, 37)
  description = "Deploy stage state changes of pipeline ${local.final_name}"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Stage Execution State Change"]
    resources   = [aws_codepipeline.pipeline.arn]
    detail = {
      stage = [local.codedeploy_stage_name]
      state = var.codedeploy_config.notify_on_states
    }
  })
}

resource "aws_cloudwatch_event_target" "codedeploy_stage_sns" {
  count     = local.codedeploy_notifications_enabled ? 1 : 0
  rule      = aws_cloudwatch_event_rule.codedeploy_stage_events[0].name
  target_id = substr("${local.final_name}_Deploy", 0, 64)
  arn       = aws_sns_topic.pipeline_notifications.arn

  retry_policy {
    maximum_retry_attempts       = 3
    maximum_event_age_in_seconds = 3600
  }

  # Plain text e-mail body instead of the raw JSON event
  input_transformer {
    input_paths = {
      pipeline  = "$.detail.pipeline"
      stage     = "$.detail.stage"
      state     = "$.detail.state"
      execution = "$.detail.execution-id"
      region    = "$.region"
      time      = "$.time"
    }
    input_template = "\"Pipeline <pipeline> - stage <stage>: <state> at <time> (execution <execution>). Details: https://<region>.console.aws.amazon.com/codesuite/codepipeline/pipelines/<pipeline>/executions/<execution>/timeline\""
  }
}

# EventBridge needs a resource-based permission to publish on the topic.
# NOTE: aws_sns_topic_policy replaces the default topic policy, so the default
# owner-account statement is restated here to keep the existing behaviour
# (notifier Lambda, e-mail subscriptions, manual approval).
data "aws_iam_policy_document" "pipeline_notifications_topic" {
  count = local.codedeploy_notifications_enabled ? 1 : 0

  statement {
    sid    = "DefaultOwnerAccountAccess"
    effect = "Allow"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish"
    ]
    resources = [aws_sns_topic.pipeline_notifications.arn]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Only the Deploy stage rule of this pipeline may publish
  statement {
    sid       = "AllowEventBridgeDeployStageRule"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.pipeline_notifications.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.codedeploy_stage_events[0].arn]
    }
  }
}

resource "aws_sns_topic_policy" "pipeline_notifications" {
  count  = local.codedeploy_notifications_enabled ? 1 : 0
  arn    = aws_sns_topic.pipeline_notifications.arn
  policy = data.aws_iam_policy_document.pipeline_notifications_topic[0].json
}
