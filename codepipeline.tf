locals {
  manual_approval_link = (
    var.add_manual_approval && var.is_codecommit ?
    data.aws_codecommit_repository.source[0].clone_url_http :
    local.github_repo_url
  )

  git_stage_src_name = "GitProviderSource"
}

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
  name_prefix        = length("${local.final_name}") > 38 ? substr("${local.final_name}", 0, 37) : "${local.final_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codepipeline.json
}

data "aws_iam_policy_document" "codepipeline_default" {
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

  # statement {
  #   effect    = "Allow"
  #   actions   = ["codestar-connections:UseConnection"]
  #   resources = [data.aws_codestarconnections_connection.git_provider[0].arn]
  # }

  dynamic "statement" {
    for_each = !var.is_codecommit ? [1] : []
    content {
      effect    = "Allow"
      actions   = ["codestar-connections:UseConnection"]
      resources = [data.aws_codestarconnections_connection.git_provider[0].arn]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:StopBuild",
      "codebuild:BatchGetBuildBatches",
      "codebuild:StartBuildBatch"
    ]

    resources = local.codebuild_projects_arns
  }

  dynamic "statement" {
    for_each = var.is_codecommit ? [1] : []
    content {
      effect = "Allow"

      actions = [
        "codecommit:Get*",
        "codecommit:List*",
        "codecommit:GitPull",
        "codecommit:BatchGet*",
        "codecommit:Describe*",
        "codecommit:UploadArchive",
        "codecommit:BatchDescribe*",
        "codecommit:EvaluatePullRequestApprovalRules",
      ]

      resources = [
        data.aws_codecommit_repository.source[0].arn
      ]
    }
  }
}

resource "aws_iam_role_policy" "codepipeline_default" {
  policy = data.aws_iam_policy_document.codepipeline_default.json
  role   = aws_iam_role.codepipeline_role.name
}

data "aws_iam_policy_document" "codepipeline_manual_approval" {
  count = var.add_manual_approval ? 1 : 0
  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.pipeline_notifications.arn
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline_manual_approval" {
  count  = var.add_manual_approval ? 1 : 0
  policy = data.aws_iam_policy_document.codepipeline_manual_approval[0].json
  role   = aws_iam_role.codepipeline_role.name
}

resource "aws_codepipeline" "pipeline" {
  name          = local.final_name
  role_arn      = aws_iam_role.codepipeline_role.arn
  pipeline_type = upper(var.codepipeline_type)
  artifact_store {
    location = aws_s3_bucket.pipeline_artifact_bucket.bucket
    type     = "S3"
  }

  # V2 pipeline cab have a trigger block to granularly define the events
  # used to trigger the pipelines
  dynamic "trigger" {
    for_each = upper(var.codepipeline_type) == "V2" && !var.is_codecommit ? [1] : []
    content {
      provider_type = "CodeStarSourceConnection"
      git_configuration {
        source_action_name = local.git_stage_src_name

        push {
          branches {
            includes = [var.repo_branch]
          }
          file_paths {
            includes = var.codepipeline_source_file_paths
          }

        }

      }
    }
  }

  # V1 source is more static and widely connected to the repo, it cannot react on
  # specific file changes
  dynamic "stage" {
    for_each = !var.is_codecommit ? [1] : []
    content {
      name = local.git_stage_src_name

      action {
        name             = local.git_stage_src_name
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["source_output"]

        configuration = {
          ConnectionArn    = data.aws_codestarconnections_connection.git_provider[0].arn
          FullRepositoryId = "${var.repo_owner}/${var.repo_name}"
          BranchName       = var.repo_branch
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.is_codecommit ? [1] : []
    content {
      name = "CodeCommitSource"
      action {
        name             = "CodeCommitSource"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeCommit"
        version          = "1"
        output_artifacts = ["source_output"]

        configuration = {
          PollForSourceChanges = false
          RepositoryName       = var.repo_name
          BranchName           = var.repo_branch
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.add_manual_approval ? [1] : []
    content {
      name = "Approve"

      action {
        name            = "ManualApproval"
        category        = "Approval"
        owner           = "AWS"
        provider        = "Manual"
        version         = "1"
        run_order       = 1
        input_artifacts = []
        configuration = {
          NotificationArn    = aws_sns_topic.pipeline_notifications.arn
          IsSummaryRequired  = "False"
          CustomData         = "Deploy of ${local.manual_approval_link} must be approved beforehand"
          ExternalEntityLink = local.manual_approval_link
        }
      }
    }
  }

  # Single stage build
  dynamic "stage" {
    for_each = !var.parallel_multiplatform_build_enabled ? [1] : []
    content {
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
          ProjectName = aws_codebuild_project.cb_project[0].name
        }
      }
    }
  }

  #region multi-platform
  dynamic "stage" {
    for_each = var.parallel_multiplatform_build_enabled ? [1] : []
    content {
      name = "Multiplatform-Cache-Build"

      dynamic "action" {
        for_each = var.parallel_multiplatform_build_enabled ? var.parallel_instances_configuration : {}
        content {
          name             = "Builder-${action.key}"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          input_artifacts  = ["source_output"]
          output_artifacts = ["build_output_${action.key}"]
          # output_artifacts = ["multiplatform_build_output"]
          version   = "1"
          run_order = 2

          configuration = {
            ProjectName = aws_codebuild_project.cache_builders[action.key].name
          }
        }
      }
    }
  }


  dynamic "stage" {
    for_each = var.parallel_multiplatform_build_enabled ? [1] : []
    content {
      name = "CreateImageIndex"

      action {
        name     = "Builder-image-index"
        category = "Build"
        owner    = "AWS"
        provider = "CodeBuild"
        # input_artifacts  = [for k, v in var.parallel_instances_configuration : "build_output_${k}"]
        input_artifacts  = ["source_output"]
        output_artifacts = ["complete_build_output"]
        version          = "1"
        run_order        = 3

        configuration = {
          ProjectName = aws_codebuild_project.image_index_builder[0].name
        }
      }
    }
  }
  #endregion
}
