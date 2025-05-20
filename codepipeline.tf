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
  name_prefix        = length("${local.final_name}${local.codepipeline_resources_suffix}") > 38 ? substr("${local.final_name}${local.codepipeline_resources_suffix}", 0, 37) : "${local.final_name}${local.codepipeline_resources_suffix}"
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
      "codebuild:StopBuild"
    ]

    resources = [aws_codebuild_project.cb_project.arn]
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
  name          = "${local.final_name}${local.codepipeline_resources_suffix}"
  role_arn      = aws_iam_role.codepipeline_role.arn
  pipeline_type = upper(var.codepipeline_type)
  artifact_store {
    location = aws_s3_bucket.pipeline_artifact_bucket.bucket
    type     = "S3"
  }

  dynamic "trigger" {
    for_each = upper(var.codepipeline_type) == "V2" ? [1] : []
    content {
      provider_type = "CodeStarSourceConnection"
      git_configuration {
        source_action_name = "Source"

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
          CustomData         = "Deploy of ${local.github_repo_url} must be approved beforehand"
          ExternalEntityLink = local.github_repo_url
        }
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
