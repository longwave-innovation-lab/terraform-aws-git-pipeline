locals {
  sns_display_text = "Pipeline notification topic "
  # This is needed since SNS DisplayName attribute is limited to 100 chars
  final_display_name = length("${local.sns_display_text} ${local.final_name}") > 100 ? "${local.sns_display_text} ${substr(local.final_name, 0, 100 - (length(local.sns_display_text) + 1))}" : "${local.sns_display_text} ${local.final_name}"
}

resource "aws_sns_topic" "pipeline_notifications" {
  name_prefix  = length("${local.final_name}${local.codepipeline_resources_suffix}") > 38 ? substr("${local.final_name}${local.codepipeline_resources_suffix}", 0, 37) : "${local.final_name}${local.codepipeline_resources_suffix}"
  display_name = local.final_display_name
}

resource "aws_sns_topic_subscription" "pipeline_notifications_lambda" {
  for_each = toset(var.sns_subscribers)

  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = each.key
}
