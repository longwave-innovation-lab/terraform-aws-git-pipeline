
resource "aws_codestarconnections_connection" "github_connection" {
  name          = "GHConnection"
  provider_type = "GitHub"
}

data "aws_iam_policy_document" "example_extra" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:*"
    ]
    resources = [
      "*"
    ]
  }
}

module "github_codepipeline" {
  source = "../.."

  repo_org                             = "Longwave-innovation"
  repo_name                            = "example_pipe"
  repo_branch                          = "main"
  existing_codestart_gh_connection_arn = aws_codestarconnections_connection.github_connection.arn

  force_delete_registry = true

  secrets_to_read = [
    "arn:aws:secretsmanager:eu-west-1:687331130220:secret:InnovationDockerCreds-vOTSnB"
  ]
  codebuild_role_additional_policy = data.aws_iam_policy_document.example_extra.json
  sns_subscribers                  = ["mirco.bozzolini@lantechlongwave.it"]
}