locals {
  codebuild_projects_arns = (
    var.parallel_multiplatform_build_enabled ?
    concat(
      [for k, v in var.parallel_instances_configuration : aws_codebuild_project.cache_builders[k].arn],
      [aws_codebuild_project.image_index_builder[0].arn]
    ) :
  [aws_codebuild_project.cb_project[0].arn])


  codebuild_projects_names = (
    var.parallel_multiplatform_build_enabled ?
    concat(
      [for k, v in var.parallel_instances_configuration : aws_codebuild_project.cache_builders[k].name],
      [aws_codebuild_project.image_index_builder[0].name]
    ) :
  [aws_codebuild_project.cb_project[0].name])

  arm64_cache_tag = "cache_arm64"
  amd64_cache_tag = "cache_amd64"
}

data "aws_iam_policy_document" "assume_role_codebuild" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name_prefix        = substr("${local.final_name}_Codebuild", 0, 38)
  assume_role_policy = data.aws_iam_policy_document.assume_role_codebuild.json
}

data "aws_iam_policy_document" "codebuild_default_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.final_name}${local.pipeline_resources_suffix}*",
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.final_name}${local.pipeline_resources_suffix}"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:Abort*",
      "s3:DeleteObject*",
      "s3:GetBucket*",
      "s3:GetObject*",
      "s3:List*",
      "s3:PutObject",
      "s3:PutObjectLegalHold",
      "s3:PutObjectRetention",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging"
    ]
    resources = [
      aws_s3_bucket.pipeline_artifact_bucket.arn,
      "${aws_s3_bucket.pipeline_artifact_bucket.arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = [
      local.registry_arn,
      "${local.registry_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codebuild_default" {
  role   = aws_iam_role.codebuild_role.name
  policy = data.aws_iam_policy_document.codebuild_default_policy.json
}

resource "aws_iam_role_policy" "codebuild_extra" {
  count  = var.codebuild_role_additional_policy != {} ? 1 : 0
  role   = aws_iam_role.codebuild_role.name
  policy = var.codebuild_role_additional_policy
}

data "aws_iam_policy_document" "codebuild_secret_policy" {
  count = length(var.secrets_to_read) > 0 ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = var.secrets_to_read
  }
}

resource "aws_iam_role_policy" "codebuild_secrets" {
  count  = length(var.secrets_to_read) > 0 ? 1 : 0
  role   = aws_iam_role.codebuild_role.name
  policy = data.aws_iam_policy_document.codebuild_secret_policy[0].json
}

data "aws_secretsmanager_secret" "secrets_to_read" {
  for_each = toset(var.secrets_to_read)
  arn      = each.key
}

resource "aws_codebuild_project" "cb_project" {
  count          = var.parallel_multiplatform_build_enabled ? 0 : 1
  name           = "${local.final_name}${local.pipeline_resources_suffix}"
  build_timeout  = var.build_minutes_timeout
  queued_timeout = var.codebuild_queue_minutes_timeout
  service_role   = aws_iam_role.codebuild_role.arn

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = var.codebuild_privileged_mode
    type                        = var.codebuild_container_type

    environment_variable {
      name  = "MULTIPLATFORM_ENABLED"
      type  = "PLAINTEXT"
      value = "False"
    }

    environment_variable {
      name  = "REPO_NAME"
      type  = "PLAINTEXT"
      value = var.repo_name
    }

    environment_variable {
      name  = "BRANCH_NAME"
      type  = "PLAINTEXT"
      value = var.repo_branch
    }

    dynamic "environment_variable" {
      for_each = var.ecr_custom_registry_name != "" ? [1] : []
      content {
        name  = "CUSTOM_REGISTRY_NAME"
        type  = "PLAINTEXT"
        value = var.ecr_custom_registry_name
      }
    }

    dynamic "environment_variable" {
      for_each = var.codebuild_additional_env_vars
      content {
        name  = environment_variable.value.name
        type  = environment_variable.value.type
        value = environment_variable.value.value
      }
    }
  }

  source {
    type         = "CODEPIPELINE"
    insecure_ssl = false
    buildspec    = var.codebuild_buildspec_path
  }

  artifacts {
    type                = "CODEPIPELINE"
    encryption_disabled = true
    packaging           = "NONE"
  }

  cache {
    type = "NO_CACHE"
  }
}


#region Multi Platform

# Here will be configured Codebuild project to build the cache layer
# that will be later used to build the multi-platform index image
resource "aws_codebuild_project" "cache_builders" {
  for_each = var.parallel_multiplatform_build_enabled ? var.parallel_instances_configuration : {}

  name           = "${local.final_name}${local.pipeline_resources_suffix}-${each.key}"
  build_timeout  = each.value.build_minutes_timeout
  queued_timeout = var.codebuild_queue_minutes_timeout
  service_role   = aws_iam_role.codebuild_role.arn

  environment {
    compute_type                = each.value.compute_type
    image                       = each.value.image
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = each.value.privileged_mode
    type                        = each.value.container_type

    environment_variable {
      name  = "MULTIPLATFORM_ENABLED"
      type  = "PLAINTEXT"
      value = "True"
    }

    environment_variable {
      name  = "CACHE_TAG"
      type  = "PLAINTEXT"
      value = each.key
    }

    environment_variable {
      name  = "PLATFORM_NAME"
      type  = "PLAINTEXT"
      value = each.value.platform_name
    }

    environment_variable {
      name  = "REPO_NAME"
      type  = "PLAINTEXT"
      value = var.repo_name
    }

    environment_variable {
      name  = "BRANCH_NAME"
      type  = "PLAINTEXT"
      value = var.repo_branch
    }

    dynamic "environment_variable" {
      for_each = var.ecr_custom_registry_name != "" ? [1] : []
      content {
        name  = "CUSTOM_REGISTRY_NAME"
        type  = "PLAINTEXT"
        value = var.ecr_custom_registry_name
      }
    }

    dynamic "environment_variable" {
      for_each = var.codebuild_additional_env_vars
      content {
        name  = environment_variable.value.name
        type  = environment_variable.value.type
        value = environment_variable.value.value
      }
    }
  }

  source {
    type         = "CODEPIPELINE"
    insecure_ssl = false
    buildspec    = each.value.buildspec_path
  }

  artifacts {
    type                = "CODEPIPELINE"
    encryption_disabled = true
    packaging           = "NONE"
  }

  cache {
    type = "NO_CACHE"
  }
}

# Here will be configured Codebuild project to build the multi-platform index image
resource "aws_codebuild_project" "image_index_builder" {
  count = var.parallel_multiplatform_build_enabled ? 1 : 0

  name           = "${local.final_name}${local.pipeline_resources_suffix}-image_index"
  build_timeout  = var.build_minutes_timeout
  queued_timeout = var.codebuild_queue_minutes_timeout
  service_role   = aws_iam_role.codebuild_role.arn

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = var.codebuild_privileged_mode
    type                        = var.codebuild_container_type

    environment_variable {
      name  = "MULTIPLATFORM_ENABLED"
      type  = "PLAINTEXT"
      value = "True"
    }

    environment_variable {
      name  = "ARM_CACHE_TAG"
      type  = "PLAINTEXT"
      value = local.arm64_cache_tag
    }

    environment_variable {
      name  = "AMD_CACHE_TAG"
      type  = "PLAINTEXT"
      value = local.amd64_cache_tag
    }

    environment_variable {
      name  = "REPO_NAME"
      type  = "PLAINTEXT"
      value = var.repo_name
    }

    environment_variable {
      name  = "BRANCH_NAME"
      type  = "PLAINTEXT"
      value = var.repo_branch
    }

    dynamic "environment_variable" {
      for_each = var.ecr_custom_registry_name != "" ? [1] : []
      content {
        name  = "CUSTOM_REGISTRY_NAME"
        type  = "PLAINTEXT"
        value = var.ecr_custom_registry_name
      }
    }

    dynamic "environment_variable" {
      for_each = var.codebuild_additional_env_vars
      content {
        name  = environment_variable.value.name
        type  = environment_variable.value.type
        value = environment_variable.value.value
      }
    }
  }

  source {
    type         = "CODEPIPELINE"
    insecure_ssl = false
    buildspec    = var.codebuild_buildspec_path
  }

  artifacts {
    type                = "CODEPIPELINE"
    encryption_disabled = true
    packaging           = "NONE"
  }

  cache {
    type = "NO_CACHE"
  }
}

#endregion
