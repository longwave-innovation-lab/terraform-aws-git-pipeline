resource "aws_codestarconnections_connection" "github_connection" {
  name          = "GHConnection"
  provider_type = "GitHub"
}

# --- CodeDeploy application and deployment group (owned by the caller) -----

resource "aws_codedeploy_app" "app" {
  name             = "my-app"
  compute_platform = "Server" # EC2/On-premises
}

data "aws_iam_policy_document" "codedeploy_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

# Service role used by CodeDeploy to read EC2 tags and manage the load balancer
resource "aws_iam_role" "codedeploy_service" {
  name               = "my-app-codedeploy-service-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json
}

resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  role       = aws_iam_role.codedeploy_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# In-place deployment on the EC2 instances tagged Name=my-app, with automatic
# rollback to the last successful revision when a deployment fails.
# To take an instance out of an ALB during the deployment switch deployment_option
# to WITH_TRAFFIC_CONTROL and add a load_balancer_info { target_group_info { name } } block.
resource "aws_codedeploy_deployment_group" "group" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "my-app-staging"
  service_role_arn       = aws_iam_role.codedeploy_service.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "my-app"
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

# --- Pipeline: Source -> Build -> Deploy -------------------------------------

module "github_codepipeline" {
  source = "../.."

  repo_owner                        = "org_name"
  repo_name                         = "repo_name"
  repo_branch                       = "branch_name"
  existing_codestart_connection_arn = aws_codestarconnections_connection.github_connection.arn
  ecr_enabled                       = false
  codebuild_privileged_mode         = false
  sns_subscribers                   = ["subscriber_mail@domain.com"]

  codedeploy_config = {
    application_name      = aws_codedeploy_app.app.name
    deployment_group_name = aws_codedeploy_deployment_group.group.deployment_group_name
    notify_on_states      = ["SUCCEEDED", "FAILED"]
  }
}

# --- Permission for the target instances -------------------------------------
# The CodeDeploy agent downloads the revision from the pipeline artifact bucket
# with the instance profile credentials: attach this policy to the EC2 role.

data "aws_iam_policy_document" "revision_read" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.github_codepipeline.artifact_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "revision_read" {
  name   = "my-app-codedeploy-revision-read"
  policy = data.aws_iam_policy_document.revision_read.json
}
