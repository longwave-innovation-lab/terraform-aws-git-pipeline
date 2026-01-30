
resource "aws_ssm_parameter" "test_parameters" {
  for_each = {
    "test" : "test",
    "test2" : "test2"
  }

  type  = "SecureString"
  name  = "/test/${each.key}"
  value = each.value
}

module "codecommit_pipeline" {
  depends_on = [aws_ssm_parameter.test_parameters]
  source     = "../.."

  is_codecommit = true
  repo_name     = "codecommit_repo_name"
  repo_branch   = "repo_branch"

  force_delete_registry            = true
  ecr_custom_registry_name         = "my_name_for_monorepos"
  ecr_scan_images_on_push          = true
  codebuild_container_type         = "ARM_CONTAINER"
  codebuild_compute_type           = "BUILD_GENERAL1_MEDIUM"
  codebuild_image                  = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
  codebuild_buildspec_path         = "my/custom/path/buildspec.yaml"
  parameters_paths_to_read         = ["/test/", "/lw/dockerhub/*"]
  ecr_image_tag_mutability         = "immutable_with_exclusion"
  ecr_mutability_exclusion_filters = ["dev-*", "qa-*", "cache"]
  sns_subscribers                  = ["mirco.bozzolini@lantechlongwave.it"]
}
