
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

data "aws_secretsmanager_secret" "secret" {
  name = "my-secret"
}

data "aws_ssm_parameter" "parameter" {
  name = "/my-paramater-path/my-parameter"
}

module "github_codepipeline" {
  depends_on = [aws_ssm_parameter.test_parameters]
  source     = "../.."

  repo_org                             = "Longwave-innovation"
  repo_name                            = "demo_pipe"
  repo_branch                          = "main"
  codepipeline_type                    = "v2"
  existing_codestart_gh_connection_arn = aws_codestarconnections_connection.github_connection.arn
  force_delete_registry                = true
  secrets_to_read                      = [data.aws_secretsmanager_secret.secret.arn]
  parameters_paths_to_read             = ["/my-paramater-path/"]
  codebuild_additional_env_vars = [{
    name  = "MY_SIMPLE_VALUE"
    type  = "PLAINTEXT"
    value = "my_value"
    }, {
    name  = "MY_SECRET_VALUE"
    type  = "SECRETS_MANAGER"
    value = "${data.aws_secretsmanager_secret.secret.name}:<secret-json-key>"
    }, {
    name  = "MY_PARAMETER_VALUE"
    type  = "PARAMETER_STORE"
    value = data.aws_ssm_parameter.parameter.name
    }
  ]
  sns_subscribers = ["subscriber_mail@domain.com"]
}
