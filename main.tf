/**
 * # terraform-aws-github-pipeline
 *
 * Module that creates a pipeline which has a Github repository as a source.
 *
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_codestarconnections_connection" "github_provider" {
  arn = var.existing_codestart_gh_connection_arn
}

locals {
  codepipeline_resources_suffix = "_GHpipeline"

  untruncated_name = "${var.repo_org}-${var.repo_name}"
  # max_name_length = 64 - length(local.codepipeline_resources_suffix)
  max_name_length = 64
  final_name = length(local.untruncated_name) > local.max_name_length ? substr(local.untruncated_name, 0, local.max_name_length) : local.untruncated_name
}