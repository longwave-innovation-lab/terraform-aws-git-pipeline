
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

  is_codecommit                    = true
  repo_name                        = "your-repo-name"
  repo_branch                      = "your-branch-to-listen"
  add_manual_approval              = true
  force_delete_registry            = true
  ecr_custom_registry_name         = "custom_name_for_registry"
  ecr_scan_images_on_push          = true
  codebuild_container_type         = "ARM_CONTAINER"
  codebuild_compute_type           = "BUILD_GENERAL1_MEDIUM"
  codebuild_image                  = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
  codebuild_buildspec_path         = "path/to/your/buildspec.yaml"
  parameters_paths_to_read         = ["/test/", "/lw/dockerhub/*"]
  ecr_image_tag_mutability         = "immutable_with_exclusion"
  ecr_mutability_exclusion_filters = ["dev-*", "qa-*", "cache"]
  sns_subscribers                  = ["mail.to.notify@domain.com"]
}
