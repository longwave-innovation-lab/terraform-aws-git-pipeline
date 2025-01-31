resource "aws_sns_topic" "pipeline_notifications" {
  name_prefix  = "${var.repo_org}-${var.repo_name}_Notifications"
  display_name = "Notification topic about the pipeline in ${var.repo_org}/${var.repo_name}"
}

resource "aws_sns_topic_subscription" "pipeline_notifications_lambda" {
  for_each = toset(var.sns_subscribers)

  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = each.key
}
