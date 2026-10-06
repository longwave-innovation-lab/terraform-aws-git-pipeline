# CodeDeploy EC2 Example <!-- omit in toc -->

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Intro](#intro)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Intro

This example shows a pipeline with an additional `Deploy` stage that uses AWS CodeDeploy to install the build output on the EC2 instances tagged `Name=my-app` (in-place deployment, automatic rollback on failure).

The CodeDeploy application, the deployment group and its service role are created outside the module and passed through `codedeploy_config`.
The example also shows the policy that the target instances need to download the revision from the pipeline artifact bucket.

Deploy stage outcomes (`SUCCEEDED`, `FAILED`) are sent to the same SNS subscribers of the build notifications.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_github_codepipeline"></a> [github\_codepipeline](#module\_github\_codepipeline) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codedeploy_app.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app) | resource |
| [aws_codedeploy_deployment_group.group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_group) | resource |
| [aws_codestarconnections_connection.github_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_connection) | resource |
| [aws_iam_policy.revision_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.codedeploy_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.codedeploy_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.codedeploy_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.revision_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_profile"></a> [profile](#input\_profile) | Aws provider profile | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Aws provider region | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_artifact_bucket_arn"></a> [artifact\_bucket\_arn](#output\_artifact\_bucket\_arn) | The Amazon Resource Name (ARN) of the pipeline artifact bucket, source of the CodeDeploy revisions. |
| <a name="output_codedeploy_stage_name"></a> [codedeploy\_stage\_name](#output\_codedeploy\_stage\_name) | Name of the CodeDeploy stage of the pipeline. |
| <a name="output_codepipeline_arn"></a> [codepipeline\_arn](#output\_codepipeline\_arn) | The Amazon Resource Name (ARN) of the CodePipeline. |
<!-- END_TF_DOCS -->
