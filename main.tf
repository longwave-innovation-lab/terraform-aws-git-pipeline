/**
 * # terraform-aws-github-pipeline
 *
 * Module that creates a pipeline which has a Github repository as a source.
 *
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_codestarconnections_connection" "github_provider" {
  arn = var.existing_codestart_gh_connection_arn
}

#region S3

locals {
  original_name = "${var.repo_org}-${var.repo_name}-articat-bucket"

  sanitized_name = lower(
    substr(
      replace(
        replace(
          replace(local.original_name, "/[^a-zA-Z0-9-]/", "-"),
          "/-+/", "-"
        ),
        "/^-|-$/", ""
      ),
      0,
      min(length(replace(replace(replace(local.original_name, "/[^a-zA-Z0-9-]/", "-"), "/-+/", "-"), "/^-|-$/", "")), 37)
    )
  )
}
resource "aws_s3_bucket" "pipeline_artifact_bucket" {
  bucket_prefix = local.sanitized_name
  force_destroy = true # Since is a bucket for artifacts, we can destroy it if needed
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.pipeline_artifact_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#endregion S3

#region ECR

# Sanitizing the name is not required anymore, it is preferred to throw an error 
# instead of faking a creation a "maybe" not functioning pipeline
resource "aws_ecr_repository" "registry" {
  name                 = var.repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = var.force_delete_registry
  image_scanning_configuration {
    scan_on_push = var.scan_images_on_push
  }
}

resource "aws_ecr_lifecycle_policy" "images_lifecycle" {
  repository = aws_ecr_repository.registry.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 2,
            "description": "Keep last ${var.images_to_keep} images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.images_to_keep}
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 1,
            "description": "Keep only one untagged image maximum",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

#endregion ECR

#region Codebuild

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
  name           = "${var.repo_org}-${var.repo_name}-project"
  build_timeout  = var.build_minutes_timeout
  queued_timeout = var.codebuild_queue_minutes_timeout
  service_role   = aws_iam_role.codebuild_role.arn

  environment {
    compute_type                = var.codebuild_comput_type
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
#endregion Codebuild

#region Codepipeline

data "aws_iam_policy_document" "assume_role_codepipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.repo_org}_${var.repo_name}_Codepipeline"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codepipeline.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.pipeline_artifact_bucket.arn,
      "${aws_s3_bucket.pipeline_artifact_bucket.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [data.aws_codestarconnections_connection.github_provider.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_default" {
  policy = data.aws_iam_policy_document.codepipeline_policy.json
  role   = aws_iam_role.codepipeline_role.name
}

resource "aws_codepipeline" "pipeline" {
  name     = "${var.repo_org}_${var.repo_name}_pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github_provider.arn
        FullRepositoryId = "${var.repo_org}/${var.repo_name}"
        BranchName       = var.repo_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.cb_project.name
      }
    }
  }
}

#endregion codepipeline
