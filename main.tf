data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_codestarconnections_connection" "github_provider" {
  arn = var.existing_codestart_gh_connection_arn
}

locals {
  codepipeline_resources_suffix = "_GHpipeline"

  untruncated_name = var.repo_org_shortname ? "${var.repo_org_shortname}-${var.repo_name}-${var.repo_branch}" : "${var.repo_org}-${var.repo_name}-${var.repo_branch}"
  github_repo_url  = "https://github.com/${var.repo_org}/${var.repo_name}"
  max_name_length  = 64
  final_name       = length(local.untruncated_name) > local.max_name_length ? substr(local.untruncated_name, 0, local.max_name_length) : local.untruncated_name
}