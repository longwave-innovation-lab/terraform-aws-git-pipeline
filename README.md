<!-- BEGIN_TF_DOCS -->
# terraform-aws-github-pipeline

Module that creates a pipeline which has a Github repository as a source.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.69.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_codebuild_project.cb_project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codepipeline.pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_ecr_lifecycle_policy.images_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_iam_role.codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codepipeline_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.codebuild_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codebuild_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codepipeline_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.pipeline_artifact_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.codepipeline_bucket_pab](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_codestarconnections_connection.github_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/codestarconnections_connection) | data source |
| [aws_iam_policy_document.assume_role_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_role_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_default_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_secret_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codepipeline_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.secrets_to_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_existing_codestart_gh_connection_arn"></a> [existing\_codestart\_gh\_connection\_arn](#input\_existing\_codestart\_gh\_connection\_arn) | Arn of the existing GitHub connection | `string` | n/a | yes |
| <a name="input_repo_branch"></a> [repo\_branch](#input\_repo\_branch) | Name of the branch to listen | `string` | n/a | yes |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | Name of the repository | `string` | n/a | yes |
| <a name="input_repo_org"></a> [repo\_org](#input\_repo\_org) | Name of the organization | `string` | n/a | yes |
| <a name="input_build_minutes_timeout"></a> [build\_minutes\_timeout](#input\_build\_minutes\_timeout) | Number of minutes to timeout the build | `number` | `5` | no |
| <a name="input_codebuild_buildspec_path"></a> [codebuild\_buildspec\_path](#input\_codebuild\_buildspec\_path) | Path to the buildspec file in the source repository | `string` | `"buildspec.yaml"` | no |
| <a name="input_codebuild_comput_type"></a> [codebuild\_comput\_type](#input\_codebuild\_comput\_type) | Compute type for the CodeBuild project. Available values: BUILD\_GENERAL1\_SMALL, BUILD\_GENERAL1\_MEDIUM, BUILD\_GENERAL1\_LARGE, BUILD\_GENERAL1\_2XLARGE | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| <a name="input_codebuild_container_type"></a> [codebuild\_container\_type](#input\_codebuild\_container\_type) | Container type for the CodeBuild project. Available values: LINUX\_CONTAINER, WINDOWS\_CONTAINER | `string` | `"LINUX_CONTAINER"` | no |
| <a name="input_codebuild_image"></a> [codebuild\_image](#input\_codebuild\_image) | Base image for the CodeBuild project | `string` | `"aws/codebuild/amazonlinux2-x86_64-standard:4.0"` | no |
| <a name="input_codebuild_privileged_mode"></a> [codebuild\_privileged\_mode](#input\_codebuild\_privileged\_mode) | Whether to run the build in privileged mode which is needed when using Docker | `bool` | `true` | no |
| <a name="input_codebuild_queue_minutes_timeout"></a> [codebuild\_queue\_minutes\_timeout](#input\_codebuild\_queue\_minutes\_timeout) | Number of minutes to timeout the codebuild queue | `number` | `60` | no |
| <a name="input_force_delete_registry"></a> [force\_delete\_registry](#input\_force\_delete\_registry) | Whether to force delete the registry, even if there are still images | `bool` | `false` | no |
| <a name="input_images_to_keep"></a> [images\_to\_keep](#input\_images\_to\_keep) | Number of images to keep in the registry | `number` | `20` | no |
| <a name="input_scan_images_on_push"></a> [scan\_images\_on\_push](#input\_scan\_images\_on\_push) | Whether to scan images on push to the registry | `bool` | `false` | no |
| <a name="input_secrets_to_read"></a> [secrets\_to\_read](#input\_secrets\_to\_read) | List of secrets to read from the repository | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codebuild_role_arn"></a> [codebuild\_role\_arn](#output\_codebuild\_role\_arn) | The Amazon Resource Name (ARN) specifying the role for Codebuild. |
| <a name="output_codepipeline_arn"></a> [codepipeline\_arn](#output\_codepipeline\_arn) | The Amazon Resource Name (ARN) of the CodePipeline. |
| <a name="output_codepipeline_role_arn"></a> [codepipeline\_role\_arn](#output\_codepipeline\_role\_arn) | The Amazon Resource Name (ARN) specifying the role for CodePipeline. |
| <a name="output_ecr_arn"></a> [ecr\_arn](#output\_ecr\_arn) | The Amazon Resource Name (ARN) of the ECR repository. |
| <a name="output_ecr_registry_name"></a> [ecr\_registry\_name](#output\_ecr\_registry\_name) | The name of the ECR repository. |
| <a name="output_ecr_registry_uri"></a> [ecr\_registry\_uri](#output\_ecr\_registry\_uri) | The URL of the ECR repository. |
<!-- END_TF_DOCS -->