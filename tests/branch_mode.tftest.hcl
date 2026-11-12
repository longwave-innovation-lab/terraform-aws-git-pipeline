mock_provider "aws" {
  mock_data "aws_codestarconnections_connection" {
    defaults = {
      arn = "arn:aws:codestar-connections:eu-west-1:111111111111:connection/mock"
    }
  }
  mock_data "aws_region" {
    defaults = {
      region = "eu-west-1"
    }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111111111111"
    }
  }
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
  mock_data "aws_ecr_lifecycle_policy_document" {
    defaults = {
      json = "{\"rules\":[]}"
    }
  }
}
mock_provider "archive" {}

variables {
  repo_owner                        = "org"
  repo_name                         = "repo"
  repo_branch                       = "feature/x"
  existing_codestart_connection_arn = "arn:aws:codestar-connections:eu-west-1:111111111111:connection/mock"
}

run "branch_mode_unchanged" {
  command = plan

  assert {
    condition     = aws_codepipeline.pipeline.name == "org-repo-feature-x"
    error_message = "pipeline name changed"
  }
  assert {
    condition     = length(aws_codepipeline.pipeline.trigger) == 1
    error_message = "trigger count changed"
  }
  assert {
    condition     = aws_codepipeline.pipeline.trigger[0].git_configuration[0].push[0].branches[0].includes == tolist(["feature/x"])
    error_message = "branch trigger changed"
  }
  assert {
    condition     = aws_codepipeline.pipeline.trigger[0].git_configuration[0].push[0].file_paths[0].includes == tolist(["**"])
    error_message = "file path trigger changed"
  }
  assert {
    condition     = length(aws_codepipeline.pipeline.trigger[0].git_configuration[0].push[0].tags) == 0
    error_message = "unexpected tags filter"
  }
  assert {
    condition     = aws_codepipeline.pipeline.stage[0].action[0].namespace == null
    error_message = "source namespace changed"
  }
  assert {
    condition     = aws_codepipeline.pipeline.stage[0].action[0].configuration["BranchName"] == "feature/x"
    error_message = "source BranchName changed"
  }
  assert {
    condition     = aws_codepipeline.pipeline.stage[1].action[0].configuration == tomap({ ProjectName = "org-repo-feature-x_Pipeline" })
    error_message = "build action configuration changed"
  }
  assert {
    condition     = one([for e in aws_codebuild_project.cb_project[0].environment[0].environment_variable : e.value if e.name == "BRANCH_NAME"]) == "feature/x"
    error_message = "BRANCH_NAME env var changed"
  }
  assert {
    condition     = aws_cloudwatch_event_rule.codebuild_events_rule.description == "Capture CodeBuild events for org/repo branch feature/x"
    error_message = "event rule description changed"
  }
  assert {
    condition     = endswith(aws_lambda_function.codebuild_event_listener.description, "for repo org/repo branch feature/x")
    error_message = "notifier description changed"
  }
}
