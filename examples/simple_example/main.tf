
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
  existing_codestart_connection_arn = aws_codestarconnections_connection.github_connection.arn

  force_delete_registry = true
  # secrets_to_read = [
  #   "arn:aws:secretsmanager:eu-west-1:687331130220:secret:InnovationDockerCreds-vOTSnB"
  # ]
  ecr_scan_images_on_push          = true
  parameters_paths_to_read         = ["/test/", "/lw/dockerhub/*"]
  ecr_image_tag_mutability         = "immutable_with_exclusion"
  ecr_mutability_exclusion_filters = ["dev-*", "qa-*"]
  ecr_external_access_arns = [
   "arn:aws:iam::111111111111:root",
   "arn:aws:iam::111111111111:role/example-eks-nodes-role"
  ]
  codebuild_role_additional_policy = data.aws_iam_policy_document.example_extra.json
  sns_subscribers                  = ["subscriber_mail@domain.com"]
}
