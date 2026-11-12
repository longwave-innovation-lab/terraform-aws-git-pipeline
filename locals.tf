locals {
  pipeline_resources_suffix = "_Pipeline"

  # --- Optional tag-push trigger ---
  tag_trigger_enabled = var.tag_trigger_enabled
  # Branch set on the source action (in tag mode AWS uses it only for manual starts)
  source_branch = local.tag_trigger_enabled ? var.tag_trigger_default_branch : var.repo_branch
  # Identifier used for naming and the BRANCH_NAME env var
  pipeline_ref_name = local.tag_trigger_enabled ? var.tag_index : var.repo_branch
  trigger_description = (
    local.tag_trigger_enabled ?
    "tags ${join(", ", var.tag_trigger_includes)}" :
    "branch ${var.repo_branch}"
  )
  source_variables_namespace = "SourceVariables"
  # Action-level env vars injected into every CodeBuild action in tag mode
  tag_build_action_configuration = local.tag_trigger_enabled ? {
    EnvironmentVariables = jsonencode([
      {
        name  = "TAG_NAME"
        value = "#{${local.source_variables_namespace}.TagName}"
        type  = "PLAINTEXT"
      }
    ])
  } : {}

  repo_branch_fixed = replace(local.pipeline_ref_name, "/", "-")
  owner_part = (
    var.is_codecommit ?
    "" :
    var.repo_owner_shortname != "" ? "${var.repo_owner_shortname}-" : "${var.repo_owner}-"
  )
  untruncated_name = "${local.owner_part}${var.repo_name}-${local.repo_branch_fixed}"
  github_repo_url  = "${var.git_provider_url}/${var.repo_owner}/${var.repo_name}"
  max_name_length  = 64
  final_name = (
    length(var.pipeline_custom_name) > 0 ? trim(var.pipeline_custom_name, " ") :
    length(local.untruncated_name) > local.max_name_length ?
    substr(local.untruncated_name, 0, local.max_name_length) : local.untruncated_name
  )

  arm64_cache_tag = "cache_arm64"
  amd64_cache_tag = "cache_amd64"

  # --- Monorepo / path-filter traffic controller ---
  # Active only when: CodeCommit repo AND caller has specified real path filters (not just the catch-all "*")
  use_lambda_trigger = (
    var.is_codecommit &&
    length(var.source_file_path_filters) > 0 &&
    # Invalidate the boolean if the only path filter is the catch-all "*", in that case we can simply use Eventbridge
    !(length(var.source_file_path_filters) == 1 && var.source_file_path_filters[0] == "*")
  )

  # --- Optional CodeDeploy stage ---
  codedeploy_enabled    = var.codedeploy_config != null
  codedeploy_stage_name = "Deploy"
  # Notifications need at least one state to listen to, otherwise no rule is created
  # (try() avoids attribute access on a null object when the stage is disabled)
  codedeploy_notifications_enabled = length(try(var.codedeploy_config.notify_on_states, [])) > 0

}
