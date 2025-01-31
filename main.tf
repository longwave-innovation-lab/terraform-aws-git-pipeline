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
