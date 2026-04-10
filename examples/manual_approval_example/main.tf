
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

  repo_owner                        = "org_name"
  repo_name                         = "repo_name"
  repo_branch                       = "branch_name"
  codepipeline_type                 = "v2"
  source_file_path_filters          = ["package.json"]
  existing_codestart_connection_arn = aws_codestarconnections_connection.github_connection.arn
  add_manual_approval               = true
  force_delete_registry             = true
  ecr_use_existing                  = true
  ecr_max_untagged_images           = 10
  secrets_to_read = [
    "arn:aws:secretsmanager:eu-west-1:123456789012:secret:InnovationDockerCreds-xxxxxx"
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
  sns_subscribers                  = ["subscriber_mail@domain.com"]
}
