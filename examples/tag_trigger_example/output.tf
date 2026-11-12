output "codepipeline_arn" {
  value       = module.github_codepipeline.codepipeline_arn
  description = "The Amazon Resource Name (ARN) of the CodePipeline."
}

output "ecr_registry_url" {
  value       = module.github_codepipeline.ecr_registry_url
  description = "The URL of the ECR repository."
}
