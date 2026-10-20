output "codepipeline_arn" {
  value       = module.github_codepipeline.codepipeline_arn
  description = "The Amazon Resource Name (ARN) of the CodePipeline."
}

output "artifact_bucket_arn" {
  value       = module.github_codepipeline.artifact_bucket_arn
  description = "The Amazon Resource Name (ARN) of the pipeline artifact bucket, source of the CodeDeploy revisions."
}

output "codedeploy_stage_name" {
  value       = module.github_codepipeline.codedeploy_stage_name
  description = "Name of the CodeDeploy stage of the pipeline."
}
