locals {
  pipeline_resources_suffix = "_Pipeline"
  repo_branch_fixed         = replace(var.repo_branch, "/", "-")
  owner_part = (
    var.is_codecommit ?
    "" :
    var.repo_owner_shortname != "" ? "${var.repo_owner_shortname}-" : "${var.repo_owner}-"
  )
  untruncated_name = "${local.owner_part}${var.repo_name}-${local.repo_branch_fixed}"
  github_repo_url  = "${var.git_provider_url}/${var.repo_owner}/${var.repo_name}"
  max_name_length  = 64
  final_name = (
    length(local.untruncated_name) > local.max_name_length ?
    substr(local.untruncated_name, 0, local.max_name_length) : local.untruncated_name
  )

  arm64_cache_tag = "cache_arm64"
  amd64_cache_tag = "cache_amd64"

  # --- Monorepo / path-filter traffic controller ---
  # Active only when: CodeCommit repo AND caller has specified real path filters (not just the catch-all "*")
  use_lambda_trigger = (
    var.is_codecommit &&
    length(var.codepipeline_source_file_paths) > 0 &&
    # Invalidate the boolean if the only path filter is the catch-all "*", in that case we can simply use Eventbridge
    !(length(var.codepipeline_source_file_paths) == 1 && var.codepipeline_source_file_paths[0] == "*")
  )

}
