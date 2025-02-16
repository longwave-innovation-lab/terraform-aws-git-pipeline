
resource "aws_cloudwatch_event_rule" "codebuild_events_rule" {
  name_prefix = length("${local.final_name}${local.codepipeline_resources_suffix}") > 38 ? substr("${local.final_name}${local.codepipeline_resources_suffix}", 0 , 37) : "${local.final_name}${local.codepipeline_resources_suffix}"
  description = "Capture CodeBuild events for ${var.repo_org}/${var.repo_name} branch ${var.repo_branch}"

  event_pattern = jsonencode({
    source      = ["aws.codebuild"]
    detail-type = ["CodeBuild Build State Change"]
    region      = [data.aws_region.current.name]
    detail = {
      build-status = ["IN_PROGRESS", "FAILED", "STOPPED", "SUCCEEDED"]
      project-name = [aws_codebuild_project.cb_project.name]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.codebuild_events_rule.name
  target_id = substr("${local.final_name}${local.codepipeline_resources_suffix}", 0, 64)
  arn       = aws_lambda_function.codebuild_event_listener.arn

  retry_policy {
    maximum_retry_attempts       = 3
    maximum_event_age_in_seconds = 60
  }

  dead_letter_config {
    arn = aws_sqs_queue.evnt_rule_target_dlq.arn
  }
}

resource "aws_sqs_queue" "evnt_rule_target_dlq" {
  name_prefix = length("${local.final_name}${local.codepipeline_resources_suffix}") > 38 ? substr("${local.final_name}${local.codepipeline_resources_suffix}", 0 , 37) : "${local.final_name}${local.codepipeline_resources_suffix}"
}
