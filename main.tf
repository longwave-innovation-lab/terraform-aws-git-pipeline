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
  original_name = "${var.repo_org}-${var.repo_name}-artifact-bucket"

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
  name           = "${var.repo_org}-${var.repo_name}-project"
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
      "codebuild:StopBuild"
    ]

    resources = [aws_codebuild_project.cb_project.arn]
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

#region EventBridge Rule

resource "aws_cloudwatch_event_rule" "codebuild_events_rule" {
  name        = "${var.repo_org}-${var.repo_name}_rule"
  description = "Capture CodeBuild events for ${var.repo_org}/${var.repo_name}"

  event_pattern = jsonencode({
    source      = ["aws.codebuild"]
    detail-type = ["CodeBuild Build State Change"]
    region      = [data.aws_region.current.name]
    detail = {
      build-status = ["IN_PROGRESS", "FAILED", "STOPPED", "SUCCEEDED"]
      project-name = [aws_codebuild_project.cb_project.name]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.codebuild_events_rule.name
  target_id = "${var.repo_org}-${var.repo_name}_RuleTarget"
  arn       = aws_lambda_function.codebuild_event_listener.arn

  retry_policy {
    maximum_retry_attempts       = 3
    maximum_event_age_in_seconds = 60
  }

  dead_letter_config {
    arn = aws_sqs_queue.evnt_rule_target_dlq.arn
  }
}

resource "aws_sqs_queue" "evnt_rule_target_dlq" {
  name = "${var.repo_org}-${var.repo_name}_events_dlq"
}

#endregion EventBridge Rule

#region Lambda

resource "aws_iam_role" "lambda_function_role" {
  name_prefix = substr("${var.repo_org}-${var.repo_name}_CodebuildEvent", 0, 37)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_function_role.name
}

data "aws_iam_policy_document" "lambda_function_policy_document" {

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds"
    ]
    resources = [aws_codebuild_project.cb_project.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [aws_sns_topic.pipeline_notifications.arn]
  }
}

resource "aws_iam_role_policy" "codebuild_describe" {
  role   = aws_iam_role.lambda_function_role.name
  policy = data.aws_iam_policy_document.lambda_function_policy_document.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_code/app.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "codebuild_event_listener" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function_payload.zip"
  function_name = "${var.repo_org}-${var.repo_name}_CodebuildEvent"
  role          = aws_iam_role.lambda_function_role.arn
  handler       = "app.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime       = "python3.9"
  architectures = ["arm64"]
  timeout       = 10
  memory_size   = 256
  environment {
    variables = {
      "SNS_TOPIC_ARN" = aws_sns_topic.pipeline_notifications.arn
    }
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.codebuild_event_listener.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.codebuild_events_rule.arn
}

#endregion Lambda

#region SNS

resource "aws_sns_topic" "pipeline_notifications" {
  name_prefix  = "${var.repo_org}-${var.repo_name}_Notifications"
  display_name = "Notification topic about the pipeline in ${var.repo_org}/${var.repo_name}"
}

resource "aws_sns_topic_subscription" "pipeline_notifications_lambda" {
  for_each = toset(var.sns_subscribers)

  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = each.key
}

#endregion SNS
