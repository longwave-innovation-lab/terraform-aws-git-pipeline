
resource "aws_codestarconnections_connection" "github_connection" {
  name          = "GHConnection"
  provider_type = "GitHub"
}

# Pipeline triggered by tag pushes (e.g. v1.2.0) instead of branch pushes.
# The pushed tag is available in the buildspec as $TAG_NAME.
module "github_codepipeline" {
  source = "../.."

  repo_owner                        = "org_name"
  repo_name                         = "repo_name"
  existing_codestart_connection_arn = aws_codestarconnections_connection.github_connection.arn

  tag_trigger_enabled  = true
  tag_trigger_includes = ["v*"]
  tag_trigger_excludes = ["v*-rc*"]
  tag_index            = "production-version"

  force_delete_registry = true
  sns_subscribers       = ["subscriber_mail@domain.com"]
}
