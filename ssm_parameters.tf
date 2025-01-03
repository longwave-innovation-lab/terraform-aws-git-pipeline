data "aws_ssm_parameters_by_path" "parameters_to_read" {
  for_each = toset(var.parameters_paths_to_read)
  path     = each.key
}

output "debug_parameters" {
  value       = flatten(concat([for parameter in data.aws_ssm_parameters_by_path.parameters_to_read : parameter.arns]))
  description = "List of created parameters flattened"
}

data "aws_iam_policy_document" "codebuild_parameter_store_policy" {
  count = length(data.aws_ssm_parameters_by_path.parameters_to_read) > 0 ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"
    ]
    # transform all data.aws_ssm_parameters_by_path.parameters_to_read into a single array to use in resources
    resources = flatten(concat([ for parameter in data.aws_ssm_parameters_by_path.parameters_to_read : parameter.arns ]))
  }
}

resource "aws_iam_role_policy" "codebuild_parameters" {
  count  = length(data.aws_ssm_parameters_by_path.parameters_to_read) > 0 ? 1 : 0
  role   = aws_iam_role.codebuild_role.name
  policy = data.aws_iam_policy_document.codebuild_parameter_store_policy[0].json
}
