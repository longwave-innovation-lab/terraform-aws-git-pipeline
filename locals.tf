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
}
