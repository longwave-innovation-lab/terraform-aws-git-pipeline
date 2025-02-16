resource "aws_sns_topic" "pipeline_notifications" {
  name_prefix  = length("${local.final_name}${local.codepipeline_resources_suffix}") > 38 ? substr("${local.final_name}${local.codepipeline_resources_suffix}", 0 , 37) : "${local.final_name}${local.codepipeline_resources_suffix}"
  display_name = "Notification topic about the pipeline in ${var.repo_org}/${var.repo_name}"
}

resource "aws_sns_topic_subscription" "pipeline_notifications_lambda" {
  for_each = toset(var.sns_subscribers)

  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = each.key
}
