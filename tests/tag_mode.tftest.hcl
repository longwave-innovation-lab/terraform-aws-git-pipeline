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
  existing_codestart_connection_arn = "arn:aws:codestar-connections:eu-west-1:111111111111:connection/mock"
  tag_trigger_enabled               = true
}

run "tag_mode_defaults" {
  command = plan

  assert {
    condition     = aws_codepipeline.pipeline.name == "org-repo-production-version"
    error_message = "pipeline name must use tag_index"
  }
  assert {
    condition     = length(aws_codepipeline.pipeline.trigger) == 1
    error_message = "exactly one trigger expected"
  }
  assert {
    condition     = aws_codepipeline.pipeline.trigger[0].git_configuration[0].push[0].tags[0].includes == tolist(["v*"])
    error_message = "default tag include must be v*"
  }
  assert {
    condition     = aws_codepipeline.pipeline.trigger[0].git_configuration[0].push[0].tags[0].excludes == null
    error_message = "excludes must be unset by default"
  }
  assert {
    condition     = length(aws_codepipeline.pipeline.trigger[0].git_configuration[0].push[0].branches) == 0 && length(aws_codepipeline.pipeline.trigger[0].git_configuration[0].push[0].file_paths) == 0
    error_message = "tag filter must not contain branches/file paths"
  }
  assert {
    condition     = aws_codepipeline.pipeline.stage[0].action[0].namespace == "SourceVariables"
    error_message = "source namespace missing"
  }
  assert {
    condition     = aws_codepipeline.pipeline.stage[0].action[0].configuration["BranchName"] == "main"
    error_message = "source BranchName must be tag_trigger_default_branch"
  }
  assert {
    condition     = jsondecode(aws_codepipeline.pipeline.stage[1].action[0].configuration["EnvironmentVariables"])[0] == { name = "TAG_NAME", value = "#{SourceVariables.TagName}", type = "PLAINTEXT" }
    error_message = "TAG_NAME action env var missing"
  }
  assert {
    condition     = one([for e in aws_codebuild_project.cb_project[0].environment[0].environment_variable : e.value if e.name == "BRANCH_NAME"]) == "production-version"
    error_message = "BRANCH_NAME must be tag_index"
  }
  assert {
    condition     = aws_cloudwatch_event_rule.codebuild_events_rule.description == "Capture CodeBuild events for org/repo tags v*"
    error_message = "event rule description wrong"
  }
}

run "tag_mode_custom" {
  command = plan

  variables {
    repo_branch                = "ignored"
    tag_index                  = "release"
    tag_trigger_includes       = ["v*", "release-*"]
    tag_trigger_excludes       = ["*-rc*"]
    tag_trigger_default_branch = "master"
  }

  assert {
    condition     = aws_codepipeline.pipeline.name == "org-repo-release"
    error_message = "pipeline name must use tag_index, not repo_branch"
  }
  assert {
    condition     = aws_codepipeline.pipeline.trigger[0].git_configuration[0].push[0].tags[0].excludes == tolist(["*-rc*"])
    error_message = "tag excludes not applied"
  }
  assert {
    condition     = aws_codepipeline.pipeline.stage[0].action[0].configuration["BranchName"] == "master"
    error_message = "custom default branch not applied"
  }
}

run "tag_mode_custom_name_precedence" {
  command = plan

  variables {
    pipeline_custom_name = "my-pipeline"
  }

  assert {
    condition     = aws_codepipeline.pipeline.name == "my-pipeline"
    error_message = "pipeline_custom_name must take precedence"
  }
}

run "tag_mode_multiplatform" {
  command = plan

  variables {
    parallel_multiplatform_build_enabled = true
  }

  assert {
    condition = alltrue([
      for s in slice(aws_codepipeline.pipeline.stage, 1, 3) : alltrue([
        for a in s.action : strcontains(a.configuration["EnvironmentVariables"], "#{SourceVariables.TagName}")
      ])
    ])
    error_message = "every build action must receive TAG_NAME"
  }
}

run "tag_mode_rejects_codecommit" {
  command = plan

  variables {
    is_codecommit = true
  }

  expect_failures = [aws_codepipeline.pipeline]
}

run "tag_mode_rejects_v1" {
  command = plan

  variables {
    codepipeline_type = "V1"
  }

  expect_failures = [aws_codepipeline.pipeline]
}

run "branch_mode_requires_repo_branch" {
  command = plan

  variables {
    tag_trigger_enabled = false
  }

  expect_failures = [aws_codepipeline.pipeline]
}
