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
