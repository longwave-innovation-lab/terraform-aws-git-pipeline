output "ecr_arn" {
  value       = aws_ecr_repository.registry.arn
  description = "The Amazon Resource Name (ARN) of the ECR repository."
}

output "ecr_registry_name" {
  value       = aws_ecr_repository.registry.name
  description = "The name of the ECR repository."
}

output "ecr_registry_uri" {
  value       = aws_ecr_repository.registry.repository_url
  description = "The URL of the ECR repository."
}

output "codepipeline_arn" {
  value       = aws_codepipeline.pipeline.arn
  description = "The Amazon Resource Name (ARN) of the CodePipeline."
}

output "codepipeline_role_arn" {
  value       = aws_iam_role.codepipeline_role.arn
  description = "The Amazon Resource Name (ARN) specifying the role for CodePipeline."
}

output "codebuild_role_arn" {
  value       = aws_iam_role.codebuild_role.arn
  description = "The Amazon Resource Name (ARN) specifying the role for Codebuild."
}

output "sns_topic_arn" {
  value       = aws_sns_topic.pipeline_notifications.arn
  description = "The Amazon Resource Name (ARN) of the SNS topic for pipeline notifications."
}

output "sns_topci_name" {
  value       = aws_sns_topic.pipeline_notifications.name
  description = "The name of the SNS topic name for pipeline notifications."
}

output "lambda_codebuild_event_listener_arn" {
  value       = aws_lambda_function.codebuild_event_listener.arn
  description = "The Amazon Resource Name (ARN) identifying the CodeBuild event listener Lambda function."
}

output "lambda_codebuild_event_listener_name" {
  value       = aws_lambda_function.codebuild_event_listener.function_name
  description = "The name identifying the CodeBuild event listener Lambda function."
}

output "lambda_codebuild_event_listener_role" {
  value       = aws_iam_role.lambda_function_role.arn
  description = "The Amazon Resource Name (ARN) identifying the IAM role for the CodeBuild event listener Lambda function."
}

output "sqs_codebuild_events_dlq" {
  value       = aws_sqs_queue.evnt_rule_target_dlq.arn
  description = "The URL of the SQS queue which holds dead-letter messages for CodeBuild events that couldn't be processed by the lambda listener."
}

output "ssm_paramaters_to_read" {
  # value       = data.aws_ssm_parameters_by_path.parameters_to_read.arns
  value       = { for k, v in data.aws_ssm_parameters_by_path.parameters_to_read : k => v.arns }
  description = "The Amazon Resource Name (ARN) of the SSM parameters to read from the SSM parameter store during pipeline execution."
}