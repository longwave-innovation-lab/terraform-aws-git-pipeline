output "ecr_arn" {
  value       = module.github_codepipeline.ecr_arn
  description = "The Amazon Resource Name (ARN) of the ECR repository."
}

output "ecr_registry_name" {
  value       = module.github_codepipeline.ecr_registry_name
  description = "The name of the ECR repository."
}

output "ecr_registry_url" {
  value       = module.github_codepipeline.ecr_registry_url
  description = "The URL of the ECR repository."
}

output "codepipeline_arn" {
  value       = module.github_codepipeline.codepipeline_arn
  description = "The Amazon Resource Name (ARN) of the CodePipeline."
}

output "codepipeline_role_arn" {
  value       = module.github_codepipeline.codepipeline_role_arn
  description = "The Amazon Resource Name (ARN) specifying the role for CodePipeline."
}

output "codebuild_role_arn" {
  value       = module.github_codepipeline.codebuild_role_arn
  description = "The Amazon Resource Name (ARN) specifying the role for Codebuild."
}

output "parameters_to_read" {
  value       = module.github_codepipeline.ssm_paramaters_to_read
  description = "The parameters that were read from SSM."
}