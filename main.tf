data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_codestarconnections_connection" "git_provider" {
  count = !var.is_codecommit ? 1 : 0
  arn   = var.existing_codestart_connection_arn
}
