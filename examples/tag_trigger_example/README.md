# Tag Trigger Example <!-- omit in toc -->

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

This example shows the creation of a `V2` pipeline triggered by Git tag pushes matching `v*` (release candidates `v*-rc*` excluded) instead of branch pushes.
Resources are named `org_name-repo_name-production-version` and the pushed tag is exposed to the buildspec as the `TAG_NAME` environment variable.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

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
| [aws_codestarconnections_connection.github_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codestarconnections_connection) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_profile"></a> [profile](#input\_profile) | Aws provider profile | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Aws provider region | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_codepipeline_arn"></a> [codepipeline\_arn](#output\_codepipeline\_arn) | The Amazon Resource Name (ARN) of the CodePipeline. |
| <a name="output_ecr_registry_url"></a> [ecr\_registry\_url](#output\_ecr\_registry\_url) | The URL of the ECR repository. |
<!-- END_TF_DOCS -->
