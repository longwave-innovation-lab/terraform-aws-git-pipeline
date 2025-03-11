# terraform-aws-github-pipeline <!-- omit from toc -->

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Intro](#intro)
- [Requirements](#requirements)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Intro

Module that creates a pipeline which has a Github repository as a source.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.6.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.69.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.codebuild_events_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_codebuild_project.cb_project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codepipeline.pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_ecr_lifecycle_policy.images_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_iam_role.codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codepipeline_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lambda_function_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.codebuild_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codebuild_describe](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codebuild_extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codebuild_parameters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codebuild_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codepipeline_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.codepipeline_manual_approval](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_basic_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.codebuild_event_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.pipeline_artifact_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.codepipeline_bucket_pab](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_sns_topic.pipeline_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.pipeline_notifications_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.evnt_rule_target_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_codestarconnections_connection.github_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/codestarconnections_connection) | data source |
| [aws_ecr_repository.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_repository) | data source |
| [aws_iam_policy_document.assume_role_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_role_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_default_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_parameter_store_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_secret_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codepipeline_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codepipeline_manual_approval](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_function_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.secrets_to_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_ssm_parameters_by_path.parameters_to_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameters_by_path) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_existing_codestart_gh_connection_arn"></a> [existing\_codestart\_gh\_connection\_arn](#input\_existing\_codestart\_gh\_connection\_arn) | Arn of the existing GitHub connection | `string` | n/a | yes |
| <a name="input_repo_branch"></a> [repo\_branch](#input\_repo\_branch) | Name of the branch to listen | `string` | n/a | yes |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | Name of the repository | `string` | n/a | yes |
| <a name="input_repo_org"></a> [repo\_org](#input\_repo\_org) | Name of the organization | `string` | n/a | yes |
| <a name="input_add_manual_approval"></a> [add\_manual\_approval](#input\_add\_manual\_approval) | Whether to add manual approval to the CodePipeline | `bool` | `false` | no |
| <a name="input_build_minutes_timeout"></a> [build\_minutes\_timeout](#input\_build\_minutes\_timeout) | Number of minutes to timeout the build | `number` | `5` | no |
| <a name="input_codebuild_buildspec_path"></a> [codebuild\_buildspec\_path](#input\_codebuild\_buildspec\_path) | Path to the buildspec file in the source repository | `string` | `"buildspec.yaml"` | no |
| <a name="input_codebuild_compute_type"></a> [codebuild\_compute\_type](#input\_codebuild\_compute\_type) | Compute type for the CodeBuild project. Available values: BUILD\_GENERAL1\_SMALL, BUILD\_GENERAL1\_MEDIUM, BUILD\_GENERAL1\_LARGE, BUILD\_GENERAL1\_2XLARGE | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| <a name="input_codebuild_container_type"></a> [codebuild\_container\_type](#input\_codebuild\_container\_type) | Container type for the CodeBuild project. Available values: LINUX\_CONTAINER, WINDOWS\_CONTAINER | `string` | `"LINUX_CONTAINER"` | no |
| <a name="input_codebuild_image"></a> [codebuild\_image](#input\_codebuild\_image) | Base image for the CodeBuild project | `string` | `"aws/codebuild/amazonlinux2-x86_64-standard:5.0"` | no |
| <a name="input_codebuild_privileged_mode"></a> [codebuild\_privileged\_mode](#input\_codebuild\_privileged\_mode) | Whether to run the build in privileged mode which is needed when using Docker | `bool` | `true` | no |
| <a name="input_codebuild_queue_minutes_timeout"></a> [codebuild\_queue\_minutes\_timeout](#input\_codebuild\_queue\_minutes\_timeout) | Number of minutes to timeout the codebuild queue | `number` | `60` | no |
| <a name="input_codebuild_role_additional_policy"></a> [codebuild\_role\_additional\_policy](#input\_codebuild\_role\_additional\_policy) | Additional policy to attach to the CodeBuild role, it must be in json | `any` | `{}` | no |
| <a name="input_codepipeline_source_file_paths"></a> [codepipeline\_source\_file\_paths](#input\_codepipeline\_source\_file\_paths) | A list of patterns of Git repository file paths that, when a commit is pushed, are to be included as criteria that starts the pipeline. Pipeline type must be V2. | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_codepipeline_type"></a> [codepipeline\_type](#input\_codepipeline\_type) | Codepipeline version, it can be `v1` or `v2`. [See documentation to choose](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-types.html) | `string` | `"V1"` | no |
| <a name="input_ecr_custom_registry_name"></a> [ecr\_custom\_registry\_name](#input\_ecr\_custom\_registry\_name) | If the repo name is not the same as the image name use this. E.g. Mono repositories with multiple projects inside | `string` | `""` | no |
| <a name="input_ecr_max_tagged_images"></a> [ecr\_max\_tagged\_images](#input\_ecr\_max\_tagged\_images) | Number of tagged images to keep in the registry | `number` | `20` | no |
| <a name="input_ecr_max_untagged_images"></a> [ecr\_max\_untagged\_images](#input\_ecr\_max\_untagged\_images) | Number of un-tagged images to keep in the registry | `number` | `1` | no |
| <a name="input_ecr_use_existing"></a> [ecr\_use\_existing](#input\_ecr\_use\_existing) | Whether to use an existing ECR repository | `bool` | `false` | no |
| <a name="input_force_delete_registry"></a> [force\_delete\_registry](#input\_force\_delete\_registry) | Whether to force delete the registry, even if there are still images | `bool` | `false` | no |
| <a name="input_parameters_paths_to_read"></a> [parameters\_paths\_to\_read](#input\_parameters\_paths\_to\_read) | List of parameters PATHS from Parameter store to read from the Codebuild project. <br> **Note**: the last part of the path, the `paramater name`, should not be present in this variable otherwise no parameters will be found at runtime. | `list(string)` | `[]` | no |
| <a name="input_repo_org_shortname"></a> [repo\_org\_shortname](#input\_repo\_org\_shortname) | This is used to name resources when repo name and repo org are too long. | `string` | `""` | no |
| <a name="input_scan_images_on_push"></a> [scan\_images\_on\_push](#input\_scan\_images\_on\_push) | Whether to scan images on push to the registry | `bool` | `false` | no |
| <a name="input_secrets_to_read"></a> [secrets\_to\_read](#input\_secrets\_to\_read) | List of secrets ARNs from SecretManager to read from the Codebuild project | `list(string)` | `[]` | no |
| <a name="input_sns_subscribers"></a> [sns\_subscribers](#input\_sns\_subscribers) | List of email addresses to subscribe to SNS notifications | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codebuild_role_arn"></a> [codebuild\_role\_arn](#output\_codebuild\_role\_arn) | The Amazon Resource Name (ARN) specifying the role for Codebuild. |
| <a name="output_codepipeline_arn"></a> [codepipeline\_arn](#output\_codepipeline\_arn) | The Amazon Resource Name (ARN) of the CodePipeline. |
| <a name="output_codepipeline_role_arn"></a> [codepipeline\_role\_arn](#output\_codepipeline\_role\_arn) | The Amazon Resource Name (ARN) specifying the role for CodePipeline. |
| <a name="output_ecr_arn"></a> [ecr\_arn](#output\_ecr\_arn) | The Amazon Resource Name (ARN) of the ECR repository. |
| <a name="output_ecr_registry_name"></a> [ecr\_registry\_name](#output\_ecr\_registry\_name) | The name of the ECR repository. |
| <a name="output_ecr_registry_url"></a> [ecr\_registry\_url](#output\_ecr\_registry\_url) | The URL of the ECR repository. |
| <a name="output_lambda_codebuild_event_listener_arn"></a> [lambda\_codebuild\_event\_listener\_arn](#output\_lambda\_codebuild\_event\_listener\_arn) | The Amazon Resource Name (ARN) identifying the CodeBuild event listener Lambda function. |
| <a name="output_lambda_codebuild_event_listener_name"></a> [lambda\_codebuild\_event\_listener\_name](#output\_lambda\_codebuild\_event\_listener\_name) | The name identifying the CodeBuild event listener Lambda function. |
| <a name="output_lambda_codebuild_event_listener_role"></a> [lambda\_codebuild\_event\_listener\_role](#output\_lambda\_codebuild\_event\_listener\_role) | The Amazon Resource Name (ARN) identifying the IAM role for the CodeBuild event listener Lambda function. |
| <a name="output_sns_topci_name"></a> [sns\_topci\_name](#output\_sns\_topci\_name) | The name of the SNS topic name for pipeline notifications. |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | The Amazon Resource Name (ARN) of the SNS topic for pipeline notifications. |
| <a name="output_sqs_codebuild_events_dlq"></a> [sqs\_codebuild\_events\_dlq](#output\_sqs\_codebuild\_events\_dlq) | The URL of the SQS queue which holds dead-letter messages for CodeBuild events that couldn't be processed by the lambda listener. |
| <a name="output_ssm_paramaters_to_read"></a> [ssm\_paramaters\_to\_read](#output\_ssm\_paramaters\_to\_read) | The Amazon Resource Name (ARN) of the SSM parameters to read from the SSM parameter store during pipeline execution. |
<!-- END_TF_DOCS -->