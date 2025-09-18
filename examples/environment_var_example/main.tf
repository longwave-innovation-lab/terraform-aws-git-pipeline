locals {
  ssm_parameters_to_create = {
    "/test/par1" : "super-secret-value-test",
    "/test/par2" : "super-secret-value-test2",
    "/test2/par1" : "super-secret-value-test3",
    "/test2/par2" : "super-secret-value-test4",
    "/test3/par1" : "super-secret-value-test5",
    "/test3/par2" : "super-secret-value-test6",
    "/test4/par1" : "super-secret-value-test7",
    "/test4/par2" : "super-secret-value-test8"
  }
  parameters_env_vars = [for k, v in aws_ssm_parameter.test_parameter : {
    name  = "MY_PARAMETER_${k}"
    type  = "PARAMETER_STORE"
    value = v.value
  }]
}

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
  for_each = {
    "/test/par1" : "super-secret-value-test",
    "/test/par2" : "super-secret-value-test2",
    "/test2/par1" : "super-secret-value-test3",
    "/test2/par2" : "super-secret-value-test4",
    "/test3/par1" : "super-secret-value-test5",
    "/test3/par2" : "super-secret-value-test6",
    "/test4/par1" : "super-secret-value-test7",
    "/test4/par2" : "super-secret-value-test8"
  }
  type  = "SecureString"
  name  = each.key
  value = each.value
}

resource "aws_secretsmanager_secret" "secret" {
  name_prefix = "test_secret"
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
  # secrets_to_read = [
  #   aws_secretsmanager_secret.secret.arn
  # ]
  parameters_paths_to_read = [
    "/test/",
    "/test2/",
    "/test3/*",
    "/test4/*"
  ]
  codebuild_additional_env_vars = concat([{
    name  = "MY_SIMPLE_VALUE"
    type  = "PLAINTEXT"
    value = "my_value"
    }, {
    name  = "MY_SECRET_VALUE"
    type  = "SECRETS_MANAGER"
    value = "${aws_secretsmanager_secret.secret.name}:test"
  }], local.parameters_env_vars)

  sns_subscribers = ["subscriber_mail@domain.com"]
}
