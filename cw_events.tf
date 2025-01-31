
resource "aws_cloudwatch_event_rule" "codebuild_events_rule" {
  name        = "${var.repo_org}-${var.repo_name}_rule"
  description = "Capture CodeBuild events for ${var.repo_org}/${var.repo_name}"

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
  target_id = "${var.repo_org}-${var.repo_name}_RuleTarget"
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
  name = "${var.repo_org}-${var.repo_name}_events_dlq"
}
