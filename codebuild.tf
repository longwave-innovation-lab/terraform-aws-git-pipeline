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
  name_prefix        = substr("${var.repo_org}_${var.repo_name}_Codebuild", 0, 38)
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
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.repo_org}-${var.repo_name}-project*",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.repo_org}-${var.repo_name}-project"
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
      aws_ecr_repository.registry.arn,
      "${aws_ecr_repository.registry.arn}/*"
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
  name           = "${local.final_name}${local.codepipeline_resources_suffix}"
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
      name  = "REPO_NAME"
      type  = "PLAINTEXT"
      value = var.repo_name
    }

    environment_variable {
      name  = "BRANCH_NAME"
      type  = "PLAINTEXT"
      value = var.repo_branch
    }

    # # make a secret env variable for each element in secrets_to_read
    # dynamic "environment_variable" {
    #   for_each = data.aws_secretsmanager_secret.secrets_to_read
    #   content {
    #     type  = "SECRETS_MANAGER"
    #     name = environment_variable.value["name"]
    #     value = environment_variable.value["name"]
    #   }
    # }
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