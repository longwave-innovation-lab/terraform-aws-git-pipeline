# Add these data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

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

resource "aws_ssm_parameter" "test_parameter" {
  type  = "SecureString"
  name  = "/test/parameter"
  value = "super-secret-value"
}

resource "aws_secretsmanager_secret" "secret" {
  name = "my-test-secret"
}

resource "aws_secretsmanager_secret_version" "secret" {
  secret_id = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode({
    "test" : "test",
    "test2" : "test2"
  })
}


module "github_codepipeline" {
  depends_on = [
    aws_ssm_parameter.test_parameter,
    aws_secretsmanager_secret.secret,
    aws_secretsmanager_secret_version.secret
  ]
  source = "../.."

  repo_org                             = "Longwave-innovation"
  repo_name                            = "demo_pipe"
  repo_branch                          = "main"
  codepipeline_type                    = "v2"
  existing_codestart_gh_connection_arn = aws_codestarconnections_connection.github_connection.arn
  force_delete_registry                = true
  ecr_custom_registry_name             = "demo_pipe_secrets"
  secrets_to_read = [
    aws_secretsmanager_secret.secret.arn
  ]
  parameters_paths_to_read = ["/test/"]
  codebuild_additional_env_vars = [{
    name  = "MY_SIMPLE_VALUE"
    type  = "PLAINTEXT"
    value = "my_value"
    }, {
    name  = "MY_SECRET_VALUE"
    type  = "SECRETS_MANAGER"
    value = "${aws_secretsmanager_secret.secret.name}:test"
    }, {
    name  = "MY_PARAMETER_VALUE"
    type  = "PARAMETER_STORE"
    value = aws_ssm_parameter.test_parameter.value
    }
  ]
  sns_subscribers = ["subscriber_mail@domain.com"]
}
