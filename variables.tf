variable "repo_name" {
  type        = string
  description = "Name of the repository"
}

variable "repo_owner" {
  type        = string
  default     = ""
  description = "Name of the organization"
  validation {
    condition     = var.is_codecommit == false ? trim(var.repo_owner, " ") != "" : true
    error_message = "Owner name is required when is not a CodeCommit repository."
  }
}

variable "repo_owner_shortname" {
  type        = string
  default     = ""
  description = "This is used to name resources when repo name and repo org are too long."
}

variable "repo_branch" {
  type        = string
  default     = ""
  description = "Name of the branch to listen. Required when `tag_trigger_enabled = false` (default branch-push mode). Ignored when `tag_trigger_enabled = true`."
}

variable "tag_trigger_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    Opt-in. When `true` the pipeline is triggered by Git **tag** pushes (filtered by `tag_trigger_includes`/`tag_trigger_excludes`) instead of branch pushes, and `repo_branch` is ignored.
    <br>Resources are named `{owner}-{repo_name}-{tag_index}` and the pushed tag is exposed to every CodeBuild action as the `TAG_NAME` environment variable (resolved from `#{SourceVariables.TagName}`).
    <br>`source_file_path_filters` is not applied to tag pushes.
    <br>**Note**: requires `codepipeline_type = "V2"` and a CodeStar connection (`is_codecommit = false`).
  EOT
}

variable "tag_trigger_includes" {
  type        = list(string)
  default     = ["v*"]
  description = "Glob patterns of Git tags that trigger the pipeline. Only used when `tag_trigger_enabled = true`."
  validation {
    condition     = length(var.tag_trigger_includes) > 0
    error_message = "tag_trigger_includes must contain at least one pattern."
  }
}

variable "tag_trigger_excludes" {
  type        = list(string)
  default     = []
  description = "Glob patterns of Git tags that must NOT trigger the pipeline. Excludes take precedence over includes. Only used when `tag_trigger_enabled = true`."
}

variable "tag_index" {
  type        = string
  default     = "production-version"
  description = "Identifier used in place of the branch to name the resources (`{owner}-{repo_name}-{tag_index}`) and as `BRANCH_NAME` CodeBuild env var. Only used when `tag_trigger_enabled = true`."
  validation {
    condition     = length(trimspace(var.tag_index)) > 0
    error_message = "tag_index must not be empty."
  }
}

variable "tag_trigger_default_branch" {
  type        = string
  default     = "main"
  description = "Branch configured on the source action when `tag_trigger_enabled = true`. AWS requires it and uses it only for manual starts (\"Release change\"), which carry no tag: `TAG_NAME` will not be resolved in that case."
}

variable "existing_codestart_connection_arn" {
  type        = string
  default     = ""
  description = "Arn of the existing GitHub connection"
  validation {
    condition     = var.is_codecommit == false ? trim(var.existing_codestart_connection_arn, " ") != "" : true
    error_message = "Connection ARN is required when is not a CodeCommit repository."
  }
}

variable "git_provider_url" {
  type        = string
  default     = "https://github.com"
  description = "URL of the git provider."
}

variable "pipeline_custom_name" {
  type        = string
  default     = ""
  description = "Custom name for the pipeline, if not set the name will be generated with the pattern {owner}-{repo_name}-{repo_branch} ({owner}-{repo_name}-{tag_index} when `tag_trigger_enabled = true`) and truncated to 64 characters if needed. This value takes precedence over the generated one. Use this in case of multiple pipelines on a monorepo."
  validation {
    condition     = length(var.pipeline_custom_name) == 0 || (length(trim(var.pipeline_custom_name, " ")) > 0 && length(trim(var.pipeline_custom_name, " ")) <= 64)
    error_message = "Custom pipeline name must be between 1 and 64 characters."

  }
}

variable "is_codecommit" {
  type        = bool
  default     = false
  description = "Whether the repository is a CodeCommit repository."
}

variable "ecr_enabled" {
  type        = bool
  default     = true
  description = "Whether ECR is enabled or not. If false no ECR resource will be created"
}

variable "ecr_scan_images_on_push" {
  type        = bool
  default     = false
  description = "Whether to scan images on push to the registry"
}

variable "ecr_external_access_arns" {
  type        = list(string)
  default     = []
  description = "List of resources that needs to access the registry. [Look here](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html) on syntax."
}

variable "force_delete_registry" {
  type        = bool
  default     = false
  description = "Whether to force delete the registry, even if there are still images"
}

variable "secrets_to_read" {
  type        = list(string)
  default     = []
  description = "List of secrets ARNs from SecretManager to read from the Codebuild project"
}

variable "parameters_paths_to_read" {
  type        = list(string)
  default     = []
  description = "List of parameters PATHS from Parameter store to read from the Codebuild project. <br> **Note**: the last part of the path, the `parameter name`, should not be present in this variable otherwise no parameters will be found at runtime."
}

variable "build_minutes_timeout" {
  type        = number
  default     = 5
  description = "Number of minutes to timeout the build"
}

variable "codebuild_queue_minutes_timeout" {
  type        = number
  default     = 60
  description = "Number of minutes to timeout the codebuild queue"
}

variable "codebuild_compute_type" {
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  description = "Compute type for the CodeBuild project. Available values: BUILD_GENERAL1_SMALL, BUILD_GENERAL1_MEDIUM, BUILD_GENERAL1_LARGE, BUILD_GENERAL1_2XLARGE"
}

variable "codebuild_image" {
  type        = string
  default     = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
  description = "Base image for the CodeBuild project"
}

variable "codebuild_container_type" {
  type        = string
  default     = "LINUX_CONTAINER"
  description = "Container type for the CodeBuild project. Available values: LINUX_CONTAINER, WINDOWS_CONTAINER"
}

variable "codebuild_privileged_mode" {
  type        = bool
  default     = true
  description = "Whether to run the build in privileged mode which is needed when using Docker"
}

variable "codebuild_buildspec_path" {
  type        = string
  default     = "buildspec.yaml"
  description = "Path to the buildspec file in the source repository"
}

variable "codebuild_additional_env_vars" {
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default     = []
  description = "List of additional environment variables to add to the CodeBuild project. See [documentation](https://docs.aws.amazon.com/codebuild/latest/APIReference/API_EnvironmentVariable.html)"
}

variable "codebuild_role_additional_policy" {
  type        = any
  default     = {}
  description = "Additional policy to attach to the CodeBuild role, it must be in json"
}

variable "sns_subscribers" {
  type        = list(string)
  default     = []
  description = "List of email addresses to subscribe to SNS notifications"
}


variable "add_manual_approval" {
  type        = bool
  default     = false
  description = "Whether to add manual approval to the CodePipeline"
}

variable "ecr_use_existing" {
  type        = bool
  default     = false
  description = "Whether to use an existing ECR repository"
}

variable "ecr_image_tag_mutability" {
  type        = string
  default     = "MUTABLE"
  description = "Mutability mode for image tags. Must be one of: `MUTABLE`, `IMMUTABLE`, `IMMUTABLE_WITH_EXCLUSION`, or `MUTABLE_WITH_EXCLUSION`."
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE", "IMMUTABLE_WITH_EXCLUSION", "MUTABLE_WITH_EXCLUSION"], upper(var.ecr_image_tag_mutability))
    error_message = "Invalid value. Available values: `MUTABLE`, `IMMUTABLE`, `IMMUTABLE_WITH_EXCLUSION`, or `MUTABLE_WITH_EXCLUSION`"
  }
}

variable "ecr_mutability_exclusion_filters" {
  type        = list(string)
  default     = []
  description = "List of tag filters that will exclude images from mutability. Only used when `ecr_image_tag_mutability` is set to `IMMUTABLE_WITH_EXCLUSION` or `MUTABLE_WITH_EXCLUSION`.  Each filter can be up to 128 characters long and can contain a maximum of 2 wildcards () and use must contain only letters, numbers, and special characters (._-)."
}

variable "ecr_custom_registry_name" {
  type        = string
  default     = ""
  description = "If the repo name is not the same as the image name use this. E.g. Mono repositories with multiple projects inside"
}

variable "ecr_override_lifecycle_policy" {
  type        = bool
  default     = false
  description = "Whether or not override the lifecycle policy of an existing ECR repository."
}

variable "ecr_max_prod_tagged_images" {
  type        = number
  default     = 20
  description = "Number of `PRODUCTION TAGGED` images to keep in the registry, where production tagged means the tags follows the X.Y.Z tags"
}

variable "ecr_prod_tag_pattern_list" {
  type        = list(string)
  default     = ["latest", "0.*.*", "1.*.*", "2.*.*"]
  description = "Tag pattern list to match production images. See [ECR lifecycle policy doc](https://docs.aws.amazon.com/AmazonECR/latest/userguide/lifecycle_policy_parameters.html#lp_tag_pattern_list)."
}

variable "ecr_max_dev_tagged_images" {
  type        = number
  default     = 10
  description = "Number of `TAGGED` images to keep in the registry"
}

variable "ecr_dev_tag_pattern_list" {
  type        = list(string)
  default     = ["dev-*.*.*"]
  description = "Tag pattern list to match development images. See [ECR lifecycle policy doc](https://docs.aws.amazon.com/AmazonECR/latest/userguide/lifecycle_policy_parameters.html#lp_tag_pattern_list)."
}

variable "ecr_max_untagged_images" {
  type        = number
  default     = 1
  description = "Number of un-tagged images to keep in the registry"
}

variable "codepipeline_type" {
  type    = string
  default = "V2"
  validation {
    condition     = contains(["V1", "V2"], var.codepipeline_type)
    error_message = "Codepipeline type must be `V1` or `V2`"
  }
  description = "Codepipeline version, it can be `V1` or `V2`. [See documentation to choose](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-types.html)"
}

variable "source_file_path_filters" {
  type        = list(string)
  default     = ["**"]
  description = "Glob patterns of file paths that trigger the pipeline on push. Supports `*`, `**`, and `?`. For GitHub/external providers, requires `codepipeline_type = \"V2\"`. For CodeCommit, leaving this as `[\"*\"]` routes events directly to the pipeline via EventBridge; setting specific patterns instead deploys a Lambda traffic controller that inspects commit diffs and triggers the pipeline only when a matching file is changed."
}

variable "codedeploy_config" {
  type = object({
    application_name      = string
    deployment_group_name = string
    notify_on_states      = optional(list(string), ["SUCCEEDED", "FAILED", "STOPPED"])
  })
  default     = null
  description = <<-EOT
    Opt-in. When set, a `Deploy` stage using AWS CodeDeploy is appended after the `Build` stage and receives the CodeBuild output artifact as the application revision (it must contain `appspec.yml` at its root).
    <br>The CodeDeploy application and deployment group are NOT created by this module: create them in the caller and pass their names here.
    <br>`notify_on_states`: Deploy stage states that are published to the pipeline SNS topic. Allowed values: `STARTED`, `SUCCEEDED`, `RESUMED`, `FAILED`, `CANCELED`, `STOPPED`, `STOPPING`. Use `[]` to disable deploy notifications.
    <br>**Note**: not compatible with `parallel_multiplatform_build_enabled = true`.
  EOT

  validation {
    condition = var.codedeploy_config == null ? true : (
      length(trimspace(var.codedeploy_config.application_name)) > 0 &&
      length(trimspace(var.codedeploy_config.deployment_group_name)) > 0
    )
    error_message = "codedeploy_config.application_name and codedeploy_config.deployment_group_name must not be empty."
  }

  validation {
    condition = var.codedeploy_config == null ? true : alltrue([
      for s in var.codedeploy_config.notify_on_states :
      contains(["STARTED", "SUCCEEDED", "RESUMED", "FAILED", "CANCELED", "STOPPED", "STOPPING"], s)
    ])
    error_message = "codedeploy_config.notify_on_states allowed values: STARTED, SUCCEEDED, RESUMED, FAILED, CANCELED, STOPPED, STOPPING."
  }
}

variable "parallel_multiplatform_build_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable parallel multiplatform build to speed up process. When enabled the default variables will be used to configure the project to build the multilayer index. When enabled `cache_arm64` and `cache_amd64` are automatically added to ECR mutability exclusion list."
}

variable "parallel_instances_configuration" {
  type = object({
    cache_amd64 = object({
      compute_type          = optional(string, "BUILD_GENERAL1_MEDIUM")
      image                 = optional(string, "aws/codebuild/amazonlinux-x86_64-standard:5.0")
      privileged_mode       = optional(bool, true)
      container_type        = optional(string, "LINUX_CONTAINER")
      buildspec_path        = optional(string, "buildspec-cache.yaml")
      build_minutes_timeout = optional(number, 15)
      platform_name         = optional(string, "linux/amd64")
    })
    cache_arm64 = object({
      compute_type          = optional(string, "BUILD_GENERAL1_MEDIUM")
      image                 = optional(string, "aws/codebuild/amazonlinux-aarch64-standard:3.0")
      privileged_mode       = optional(bool, true)
      container_type        = optional(string, "ARM_CONTAINER")
      buildspec_path        = optional(string, "buildspec-cache.yaml")
      build_minutes_timeout = optional(number, 15)
      platform_name         = optional(string, "linux/arm64")
    })
  })
  default = {
    cache_amd64 = {
      compute_type    = "BUILD_GENERAL1_MEDIUM"
      image           = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
      privileged_mode = true
      container_type  = "LINUX_CONTAINER"
      buildspec_path  = "buildspec-cache.yaml"
    }
    cache_arm64 = {
      compute_type    = "BUILD_GENERAL1_MEDIUM"
      image           = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
      privileged_mode = true
      container_type  = "ARM_CONTAINER"
      buildspec_path  = "buildspec-cache.yaml"
    }
  }
  description = "Configuration for both environments. To know about possible values check [CodeBuild doc](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html)."
}
