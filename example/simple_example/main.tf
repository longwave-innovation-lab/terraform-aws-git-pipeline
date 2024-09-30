
resource "aws_codestarconnections_connection" "github_connection" {
  name          = "GHConnection"
  provider_type = "GitHub"
}

module "github_codepipeline" {
  source = "../.."

  repo_org                             = "Longwave-innovation"
  repo_name                            = "demo-pipe"
  repo_branch                          = "main"
  existing_codestart_gh_connection_arn = aws_codestarconnections_connection.github_connection.arn

  force_delete_registry = true
}
