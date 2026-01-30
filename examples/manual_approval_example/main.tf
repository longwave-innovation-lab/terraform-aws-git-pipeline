
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

resource "aws_ssm_parameter" "test_parameters" {
  for_each = {
    "test" : "test",
    "test2" : "test2"
  }

  type  = "SecureString"
  name  = "/test/${each.key}"
  value = each.value
}

module "github_codepipeline" {
  depends_on = [aws_ssm_parameter.test_parameters]
  source     = "../.."

  repo_owner                        = "Longwave-innovation"
  repo_name                         = "demo_pipe"
  repo_branch                       = "main"
  codepipeline_type                 = "v2"
  codepipeline_source_file_paths    = ["package.json"]
  existing_codestart_connection_arn = aws_codestarconnections_connection.github_connection.arn
  add_manual_approval               = true
  force_delete_registry             = true
  ecr_use_existing                  = true
  ecr_max_untagged_images           = 10
  secrets_to_read = [
    "arn:aws:secretsmanager:eu-west-1:687331130220:secret:InnovationDockerCreds-vOTSnB"
  ]
  codebuild_additional_env_vars = [{
    name  = "TEST1"
    type  = "PLAINTEXT"
    value = "test1"
    }, {
    name  = "TEST2"
    type  = "PLAINTEXT"
    value = "test2"
    }
  ]
  parameters_paths_to_read         = ["/test/"]
  codebuild_role_additional_policy = data.aws_iam_policy_document.example_extra.json
  sns_subscribers                  = ["mirco.bozzolini@longwave.it"]
}
