variable "repo_name" {
  type        = string
  description = "Name of the repository"
}

variable "repo_org" {
  type        = string
  description = "Name of the organization"
}

variable "repo_branch" {
  type        = string
  description = "Name of the branch to listen"
}

variable "existing_codestart_gh_connection_arn" {
  type        = string
  description = "Arn of the existing GitHub connection"
}

variable "scan_images_on_push" {
  type        = bool
  default     = false
  description = "Whether to scan images on push to the registry"
}

variable "force_delete_registry" {
  type        = bool
  default     = false
  description = "Whether to force delete the registry, even if there are still images"
}

variable "images_to_keep" {
  type        = number
  default     = 20
  description = "Number of images to keep in the registry"
}

variable "secrets_to_read" {
  type        = list(string)
  default     = []
  description = "List of secrets ARNs from SecretManager to read from the Codebuild project"
}

variable "parameters_paths_to_read" {
  type        = list(string)
  default     = []
  description = "List of parameters PATHS from Parameter store to read from the Codebuild project. Note: the last part of the path, the paramater name, should not be present in this variable otherwise no parameters will be found at runtime."
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

variable "use_existing_ecr" {
  type        = bool
  default     = false
  description = "Whether to use an existing ECR repository"
}
