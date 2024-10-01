
resource "aws_codestarconnections_connection" "github_connection" {
  name          = "GHConnection"
  provider_type = "GitHub"
}

module "github_codepipeline" {
  source = "../.."

  repo_org                             = "Longwave-innovation"
  repo_name                            = "demo_pipe"
  repo_branch                          = "main"
  existing_codestart_gh_connection_arn = aws_codestarconnections_connection.github_connection.arn

  force_delete_registry = true

  secrets_to_read = [
    "arn:aws:secretsmanager:eu-west-1:687331130220:secret:InnovationDockerCreds-vOTSnB"
  ]
}