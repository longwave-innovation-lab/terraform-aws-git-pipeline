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
<!-- END_TF_DOCS -->
