# terraform-aws-github-pipeline <!-- omit from toc -->

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Intro](#intro)
- [Usage](#usage)
  - [Basic Pipeline](#basic-pipeline)
  - [Basic Manual Approval](#basic-manual-approval)
  - [Using Environment Variables](#using-environment-variables)
- [CodeBuild Enviroment Configuration](#codebuild-enviroment-configuration)
- [Parallel multiplatform](#parallel-multiplatform)
- [Requirements](#requirements)
- [Providers](#providers)
- [Modules](#modules)
- [Resources](#resources)
- [Inputs](#inputs)
- [Outputs](#outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Intro

Module that creates a pipeline which has a Github repository as a source.

The pipeline structure is very basic at the moment.
<br>In this version it creates a source stage followed by an optional manual approval and finally a build stage.

## Usage

Here's some examples on how to used the module.

To further customize the pipeline behavior look ad [input arguments](#inputs).

### Basic Pipeline

Very basic pipeline which creates a registry, notifies a list of subscriber upon codebuild events and listen to push events on a branch over a github repository.

[Try the terraform code](./examples/simple_example/README.md).

```hcl
resource "aws_codestarconnections_connection" "github_connection" {
  name          = "GHConnection"
  provider_type = "GitHub"
}

module "github_codepipeline" {
  source                               = "git::https://github.com/Longwave-innovation/terraform-aws-github-pipeline.git?ref=v0.7.0"
  repo_owner                             = "org_name"
  repo_name                            = "repo_name"
  repo_branch                          = "branch_name"
  existing_codestart_connection_arn = aws_codestarconnections_connection.github_connection.arn
  force_delete_registry                = true
  sns_subscribers                      = ["subscriber_mail@domain.com"]
}
```

### Basic Manual Approval

Thanks to the input argument `add_manual_approval` you can seamlessly add an approval step between the source and build stages.

The SNS service will send to all pipeline subscribers a notification upon requirement of an approval.

Users must be logged in and have permissions to approve such stage to make the pipeline continue.

Since the pipeline mode will be `SUPERSEDED` each commit push will invalidate previous approval requests.

[Try the terraform code](./examples/manual_approval_example/README.md).

```hcl
resource "aws_codestarconnections_connection" "github_connection" {
  name          = "GHConnection"
  provider_type = "GitHub"
}

module "github_codepipeline" {
  source                               = "git::https://github.com/Longwave-innovation/terraform-aws-github-pipeline.git?ref=v0.7.0"
  repo_owner                             = "org_name"
  repo_name                            = "repo_name"
  repo_branch                          = "branch_name"
  add_manual_approval                  = true
  existing_codestart_connection_arn = aws_codestarconnections_connection.github_connection.arn
  force_delete_registry                = true
  sns_subscribers                      = ["subscriber_mail@domain.com"]
}
```

### Using Environment Variables

This module can handle secrets and parameters in a secure way, since the values are injected at runtime into the environment variables.

To do this we need:

1. Grant permissions to the CodeBuild resource to read parameters and secrets:

    ```hcl
    secrets_to_read          = [data.aws_secretsmanager_secret.secret.arn]    # ARNs of secrets to access
    parameters_paths_to_read = ["/my-paramater-path/"]    # Parameter Store paths to access
    ```

2. Setup the environment variables to be injected at runtime, see [official docs](https://docs.aws.amazon.com/codebuild/latest/APIReference/API_EnvironmentVariable.html):

   ```hcl
    codebuild_additional_env_vars = [{
        name  = "MY_SIMPLE_VALUE"
        type  = "PLAINTEXT"    # For non-sensitive values
        value = "my_value"
    }, {
        name  = "MY_SECRET_VALUE"
        type  = "SECRETS_MANAGER"    # For sensitive values from Secrets Manager
        value = "${data.aws_secretsmanager_secret.secret.name}:<secret-json-key>"
    }, {
        name  = "MY_PARAMETER_VALUE"
        type  = "PARAMETER_STORE"    # For configuration values from Parameter Store
        value = data.aws_ssm_parameter.parameter.name
    }]

   ```

[Try the terraform code](./examples/environment_var_example/README.md).

**Here's the complete example**:

```hcl
resource "aws_codestarconnections_connection" "github_connection" {
  name          = "GHConnection"
  provider_type = "GitHub"
}

data "aws_secretsmanager_secret" "secret" {
  name = "my-secret"
}

data "aws_ssm_parameter" "parameter" {
  name = "/my-paramater-path/my-parameter"
}

module "github_codepipeline" {
  source                               = "git::https://github.com/Longwave-innovation/terraform-aws-github-pipeline.git?ref=v0.7.0"
  repo_owner                             = "org_name"
  repo_name                            = "repo_name"
  repo_branch                          = "branch_name"
  codepipeline_type                    = "v2"
  existing_codestart_connection_arn = aws_codestarconnections_connection.github_connection.arn
  force_delete_registry                = true
  secrets_to_read                      = [data.aws_secretsmanager_secret.secret.arn]
  parameters_paths_to_read             = ["/my-paramater-path/"]
  codebuild_additional_env_vars = [{
    name  = "MY_SIMPLE_VALUE"
    type  = "PLAINTEXT"
    value = "my_value"
    }, {
    name  = "MY_SECRET_VALUE"
    type  = "SECRETS_MANAGER"
    value = "${data.aws_secretsmanager_secret.secret.name}:<secret-json-key>"
    }, {
    name  = "MY_PARAMETER_VALUE"
    type  = "PARAMETER_STORE"
    value = data.aws_ssm_parameter.parameter.name
    }
  ]
  sns_subscribers = ["subscriber_mail@domain.com"]
}
```

## CodeBuild Enviroment Configuration

You can use different configuration to customize your CodeBuild project where the automation will run.

For the complete list of available images use this command:

```sh
aws codebuild list-curated-environment-images
```

Other detail can be read on the [official documentation page](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html).

## Parallel multiplatform

Multi-platform pipelines generate an Image Index in ECR. Due to virtualization of different architectures, this process takes significantly longer when run on the same instance.

To speed up the pipeline, when parallel multiplatform mode is enabled, the workflow structure changes as follows:

1. **Source Stage** - Connected to Git Repository
2. **Multiplatform-Cache-Build Stage** (runs in parallel):
   - ARM64 Builder - runs on ARM instance, pushes cache to ECR
   - x86_64 (AMD64) Builder - runs on x86_64 instance, pushes cache to ECR
3. **CreateImageIndex Stage**:
   - Reads the cache from ECR
   - Creates the Image Index
   - Pushes to ECR the final image with proper tag

To enable this feature, set `parallel_multiplatform_build_enabled = true` in your module configuration.

Due to this structure, you need two different `buildspec.yaml` files: one for cache creation and one for the image index. Alternatively, you can use the same file with a script that checks for the `CACHE_TAG` environment variable to determine whether to build cache layers or create the final image index.

Each cache builder instance can be configured using the following parameters:

```hcl
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
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.7.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.codebuild_events_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.repo_changes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_codebuild_project.cache_builders](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codebuild_project.cb_project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codebuild_project.image_index_builder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project) | resource |
| [aws_codepipeline.pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline) | resource |
| [aws_ecr_lifecycle_policy.images_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.external_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_iam_policy.start_pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.codebuild_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.codecommit_changes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
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
| [aws_iam_role_policy_attachment.start_pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.codebuild_event_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_eventbridge](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.pipeline_artifact_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.codepipeline_bucket_pab](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_sns_topic.pipeline_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.pipeline_notifications_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.evnt_rule_target_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_codecommit_repository.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/codecommit_repository) | data source |
| [aws_codestarconnections_connection.git_provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/codestarconnections_connection) | data source |
| [aws_ecr_lifecycle_policy_document.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_lifecycle_policy_document) | data source |
| [aws_ecr_repository.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_repository) | data source |
| [aws_iam_policy_document.assume_role_codebuild](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_role_codepipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_default_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_parameter_store_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codebuild_secret_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codepipeline_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.codepipeline_manual_approval](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecr_ext_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.event_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_function_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.start_pipeline](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.secrets_to_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_ssm_parameters_by_path.parameters_to_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameters_by_path) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_repo_branch"></a> [repo\_branch](#input\_repo\_branch) | Name of the branch to listen | `string` | n/a | yes |
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | Name of the repository | `string` | n/a | yes |
| <a name="input_add_manual_approval"></a> [add\_manual\_approval](#input\_add\_manual\_approval) | Whether to add manual approval to the CodePipeline | `bool` | `false` | no |
| <a name="input_build_minutes_timeout"></a> [build\_minutes\_timeout](#input\_build\_minutes\_timeout) | Number of minutes to timeout the build | `number` | `5` | no |
| <a name="input_codebuild_additional_env_vars"></a> [codebuild\_additional\_env\_vars](#input\_codebuild\_additional\_env\_vars) | List of additional environment variables to add to the CodeBuild project. See [documentation](https://docs.aws.amazon.com/codebuild/latest/APIReference/API_EnvironmentVariable.html) | <pre>list(object({<br/>    name  = string<br/>    type  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_codebuild_buildspec_path"></a> [codebuild\_buildspec\_path](#input\_codebuild\_buildspec\_path) | Path to the buildspec file in the source repository | `string` | `"buildspec.yaml"` | no |
| <a name="input_codebuild_compute_type"></a> [codebuild\_compute\_type](#input\_codebuild\_compute\_type) | Compute type for the CodeBuild project. Available values: BUILD\_GENERAL1\_SMALL, BUILD\_GENERAL1\_MEDIUM, BUILD\_GENERAL1\_LARGE, BUILD\_GENERAL1\_2XLARGE | `string` | `"BUILD_GENERAL1_SMALL"` | no |
| <a name="input_codebuild_container_type"></a> [codebuild\_container\_type](#input\_codebuild\_container\_type) | Container type for the CodeBuild project. Available values: LINUX\_CONTAINER, WINDOWS\_CONTAINER | `string` | `"LINUX_CONTAINER"` | no |
| <a name="input_codebuild_image"></a> [codebuild\_image](#input\_codebuild\_image) | Base image for the CodeBuild project | `string` | `"aws/codebuild/amazonlinux-x86_64-standard:5.0"` | no |
| <a name="input_codebuild_privileged_mode"></a> [codebuild\_privileged\_mode](#input\_codebuild\_privileged\_mode) | Whether to run the build in privileged mode which is needed when using Docker | `bool` | `true` | no |
| <a name="input_codebuild_queue_minutes_timeout"></a> [codebuild\_queue\_minutes\_timeout](#input\_codebuild\_queue\_minutes\_timeout) | Number of minutes to timeout the codebuild queue | `number` | `60` | no |
| <a name="input_codebuild_role_additional_policy"></a> [codebuild\_role\_additional\_policy](#input\_codebuild\_role\_additional\_policy) | Additional policy to attach to the CodeBuild role, it must be in json | `any` | `{}` | no |
| <a name="input_codepipeline_source_file_paths"></a> [codepipeline\_source\_file\_paths](#input\_codepipeline\_source\_file\_paths) | A list of patterns of Git repository file paths that, when a commit is pushed, are to be included as criteria that starts the pipeline. Pipeline type must be V2. | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_codepipeline_type"></a> [codepipeline\_type](#input\_codepipeline\_type) | Codepipeline version, it can be `v1` or `v2`. [See documentation to choose](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-types.html) | `string` | `"V1"` | no |
| <a name="input_ecr_custom_registry_name"></a> [ecr\_custom\_registry\_name](#input\_ecr\_custom\_registry\_name) | If the repo name is not the same as the image name use this. E.g. Mono repositories with multiple projects inside | `string` | `""` | no |
| <a name="input_ecr_dev_tag_pattern_list"></a> [ecr\_dev\_tag\_pattern\_list](#input\_ecr\_dev\_tag\_pattern\_list) | Tag pattern list to match development images. See [ECR lifecycle policy doc](https://docs.aws.amazon.com/AmazonECR/latest/userguide/lifecycle_policy_parameters.html#lp_tag_pattern_list). | `list(string)` | <pre>[<br/>  "dev-*.*.*"<br/>]</pre> | no |
| <a name="input_ecr_external_access_arns"></a> [ecr\_external\_access\_arns](#input\_ecr\_external\_access\_arns) | List of resources that needs to access the registry. [Look here](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html) on syntax. | `list(string)` | `[]` | no |
| <a name="input_ecr_image_tag_mutability"></a> [ecr\_image\_tag\_mutability](#input\_ecr\_image\_tag\_mutability) | Mutability mode for image tags. Must be one of: `MUTABLE`, `IMMUTABLE`, `IMMUTABLE_WITH_EXCLUSION`, or `MUTABLE_WITH_EXCLUSION`. | `string` | `"MUTABLE"` | no |
| <a name="input_ecr_max_dev_tagged_images"></a> [ecr\_max\_dev\_tagged\_images](#input\_ecr\_max\_dev\_tagged\_images) | Number of `TAGGED` images to keep in the registry | `number` | `10` | no |
| <a name="input_ecr_max_prod_tagged_images"></a> [ecr\_max\_prod\_tagged\_images](#input\_ecr\_max\_prod\_tagged\_images) | Number of `PRODUCTION TAGGED` images to keep in the registry, where production tagged means the tags follows the X.Y.Z tags | `number` | `20` | no |
| <a name="input_ecr_max_untagged_images"></a> [ecr\_max\_untagged\_images](#input\_ecr\_max\_untagged\_images) | Number of un-tagged images to keep in the registry | `number` | `1` | no |
| <a name="input_ecr_mutability_exclusion_filters"></a> [ecr\_mutability\_exclusion\_filters](#input\_ecr\_mutability\_exclusion\_filters) | List of tag filters that will exclude images from mutability. Only used when `ecr_image_tag_mutability` is set to `IMMUTABLE_WITH_EXCLUSION` or `MUTABLE_WITH_EXCLUSION`.  Each filter can be up to 128 characters long and can contain a maximum of 2 wildcards () and use must contain only letters, numbers, and special characters (.\_-). | `list(string)` | `[]` | no |
| <a name="input_ecr_override_lifecycle_policy"></a> [ecr\_override\_lifecycle\_policy](#input\_ecr\_override\_lifecycle\_policy) | Whether or not override the lifecycle policy of an existing ECR repository. | `bool` | `false` | no |
| <a name="input_ecr_prod_tag_pattern_list"></a> [ecr\_prod\_tag\_pattern\_list](#input\_ecr\_prod\_tag\_pattern\_list) | Tag pattern list to match production images. See [ECR lifecycle policy doc](https://docs.aws.amazon.com/AmazonECR/latest/userguide/lifecycle_policy_parameters.html#lp_tag_pattern_list). | `list(string)` | <pre>[<br/>  "latest",<br/>  "0.*.*",<br/>  "1.*.*",<br/>  "2.*.*"<br/>]</pre> | no |
| <a name="input_ecr_scan_images_on_push"></a> [ecr\_scan\_images\_on\_push](#input\_ecr\_scan\_images\_on\_push) | Whether to scan images on push to the registry | `bool` | `false` | no |
| <a name="input_ecr_use_existing"></a> [ecr\_use\_existing](#input\_ecr\_use\_existing) | Whether to use an existing ECR repository | `bool` | `false` | no |
| <a name="input_existing_codestart_connection_arn"></a> [existing\_codestart\_connection\_arn](#input\_existing\_codestart\_connection\_arn) | Arn of the existing GitHub connection | `string` | `""` | no |
| <a name="input_force_delete_registry"></a> [force\_delete\_registry](#input\_force\_delete\_registry) | Whether to force delete the registry, even if there are still images | `bool` | `false` | no |
| <a name="input_git_provider_url"></a> [git\_provider\_url](#input\_git\_provider\_url) | URL of the git provider. | `string` | `"https://github.com"` | no |
| <a name="input_is_codecommit"></a> [is\_codecommit](#input\_is\_codecommit) | Whether the repository is a CodeCommit repository. | `bool` | `false` | no |
| <a name="input_parallel_instances_configuration"></a> [parallel\_instances\_configuration](#input\_parallel\_instances\_configuration) | Configuration for both environments. To know about possible values check [CodeBuild doc](https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html). | <pre>object({<br/>    cache_amd64 = object({<br/>      compute_type          = optional(string, "BUILD_GENERAL1_MEDIUM")<br/>      image                 = optional(string, "aws/codebuild/amazonlinux-x86_64-standard:5.0")<br/>      privileged_mode       = optional(bool, true)<br/>      container_type        = optional(string, "LINUX_CONTAINER")<br/>      buildspec_path        = optional(string, "buildspec-cache.yaml")<br/>      build_minutes_timeout = optional(number, 15)<br/>      platform_name         = optional(string, "linux/amd64")<br/>    })<br/>    cache_arm64 = object({<br/>      compute_type          = optional(string, "BUILD_GENERAL1_MEDIUM")<br/>      image                 = optional(string, "aws/codebuild/amazonlinux-aarch64-standard:3.0")<br/>      privileged_mode       = optional(bool, true)<br/>      container_type        = optional(string, "ARM_CONTAINER")<br/>      buildspec_path        = optional(string, "buildspec-cache.yaml")<br/>      build_minutes_timeout = optional(number, 15)<br/>      platform_name         = optional(string, "linux/arm64")<br/>    })<br/>  })</pre> | <pre>{<br/>  "cache_amd64": {<br/>    "buildspec_path": "buildspec-cache.yaml",<br/>    "compute_type": "BUILD_GENERAL1_MEDIUM",<br/>    "container_type": "LINUX_CONTAINER",<br/>    "image": "aws/codebuild/amazonlinux-x86_64-standard:5.0",<br/>    "privileged_mode": true<br/>  },<br/>  "cache_arm64": {<br/>    "buildspec_path": "buildspec-cache.yaml",<br/>    "compute_type": "BUILD_GENERAL1_MEDIUM",<br/>    "container_type": "ARM_CONTAINER",<br/>    "image": "aws/codebuild/amazonlinux-aarch64-standard:3.0",<br/>    "privileged_mode": true<br/>  }<br/>}</pre> | no |
| <a name="input_parallel_multiplatform_build_enabled"></a> [parallel\_multiplatform\_build\_enabled](#input\_parallel\_multiplatform\_build\_enabled) | Whether to enable parallel multiplatform build to speed up process. When enabled the default variables will be used to configure the project to build the multilayer index. When enabled `cache_arm64` and `cache_amd64` are automatically added to ECR mutability exclusion list. | `bool` | `false` | no |
| <a name="input_parameters_paths_to_read"></a> [parameters\_paths\_to\_read](#input\_parameters\_paths\_to\_read) | List of parameters PATHS from Parameter store to read from the Codebuild project. <br> **Note**: the last part of the path, the `paramater name`, should not be present in this variable otherwise no parameters will be found at runtime. | `list(string)` | `[]` | no |
| <a name="input_repo_owner"></a> [repo\_owner](#input\_repo\_owner) | Name of the organization | `string` | `""` | no |
| <a name="input_repo_owner_shortname"></a> [repo\_owner\_shortname](#input\_repo\_owner\_shortname) | This is used to name resources when repo name and repo org are too long. | `string` | `""` | no |
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
| <a name="output_fixed_path_ssm_paramaters_to_read"></a> [fixed\_path\_ssm\_paramaters\_to\_read](#output\_fixed\_path\_ssm\_paramaters\_to\_read) | The Amazon Resource Name (ARN) of the SSM parameters with a fixed path that the pipeline will have access. |
| <a name="output_lambda_codebuild_event_listener_arn"></a> [lambda\_codebuild\_event\_listener\_arn](#output\_lambda\_codebuild\_event\_listener\_arn) | The Amazon Resource Name (ARN) identifying the CodeBuild event listener Lambda function. |
| <a name="output_lambda_codebuild_event_listener_name"></a> [lambda\_codebuild\_event\_listener\_name](#output\_lambda\_codebuild\_event\_listener\_name) | The name identifying the CodeBuild event listener Lambda function. |
| <a name="output_lambda_codebuild_event_listener_role"></a> [lambda\_codebuild\_event\_listener\_role](#output\_lambda\_codebuild\_event\_listener\_role) | The Amazon Resource Name (ARN) identifying the IAM role for the CodeBuild event listener Lambda function. |
| <a name="output_sns_topci_name"></a> [sns\_topci\_name](#output\_sns\_topci\_name) | The name of the SNS topic name for pipeline notifications. |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | The Amazon Resource Name (ARN) of the SNS topic for pipeline notifications. |
| <a name="output_sqs_codebuild_events_dlq"></a> [sqs\_codebuild\_events\_dlq](#output\_sqs\_codebuild\_events\_dlq) | The URL of the SQS queue which holds dead-letter messages for CodeBuild events that couldn't be processed by the lambda listener. |
| <a name="output_wildcard_path_ssm_parameters_to_read"></a> [wildcard\_path\_ssm\_parameters\_to\_read](#output\_wildcard\_path\_ssm\_parameters\_to\_read) | The SSM parameters with a wildcard path that the pipeline will have access. |
<!-- END_TF_DOCS -->
