output "ecr_arn" {
  value       = module.codecommit_pipeline.ecr_arn
  description = "The Amazon Resource Name (ARN) of the ECR repository."
}

output "ecr_registry_name" {
  value       = module.codecommit_pipeline.ecr_registry_name
  description = "The name of the ECR repository."
}

output "ecr_registry_url" {
  value       = module.codecommit_pipeline.ecr_registry_url
  description = "The URL of the ECR repository."
}

output "codepipeline_arn" {
  value       = module.codecommit_pipeline.codepipeline_arn
  description = "The Amazon Resource Name (ARN) of the CodePipeline."
}

output "codepipeline_role_arn" {
  value       = module.codecommit_pipeline.codepipeline_role_arn
  description = "The Amazon Resource Name (ARN) specifying the role for CodePipeline."
}

output "codebuild_role_arn" {
  value       = module.codecommit_pipeline.codebuild_role_arn
  description = "The Amazon Resource Name (ARN) specifying the role for Codebuild."
}

output "parameters_to_read" {
  value       = module.codecommit_pipeline.fixed_path_ssm_paramaters_to_read
  description = "The parameters that were read from SSM."
}
