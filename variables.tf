variable "repo_name" {
  type        = string
  description = "Name of the repository"
}

variable "repo_org" {
  type        = string
  description = "Name of the organization"
}

variable "repo_org_shortname" {
  type        = string
  default     = ""
  description = "This is used to name resources when repo name and repo org are too long."
}

variable "repo_branch" {
  type        = string
  description = "Name of the branch to listen"
}

variable "existing_codestart_gh_connection_arn" {
  type        = string
  description = "Arn of the existing GitHub connection"
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
  description = "List of parameters PATHS from Parameter store to read from the Codebuild project. <br> **Note**: the last part of the path, the `paramater name`, should not be present in this variable otherwise no parameters will be found at runtime."
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
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
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

variable "sns_subscribers" {
  type        = list(string)
  default     = []
  description = "List of email addresses to subscribe to SNS notifications"
}

variable "codebuild_role_additional_policy" {
  type        = any
  default     = {}
  description = "Additional policy to attach to the CodeBuild role, it must be in json"
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
  type        = string
  default     = "V1"
  description = "Codepipeline version, it can be `v1` or `v2`. [See documentation to choose](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-types.html)"
}

variable "codepipeline_source_file_paths" {
  type        = list(string)
  default     = ["*"]
  description = "A list of patterns of Git repository file paths that, when a commit is pushed, are to be included as criteria that starts the pipeline. Pipeline type must be V2."
}
