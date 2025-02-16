## [0.2.4](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.2.3...v0.2.4) (2025-02-16)


### Bug Fixes

* now the same suffix is used on all resources and all nameprefixes are valued correctly closes [#7](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/issues/7) closes [#8](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/issues/8) ([6baef40](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/6baef4097afc1d2e4b830ff11f239592873f7cf1))

## [0.2.3](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.2.2...v0.2.3) (2025-02-16)


### Bug Fixes

* **lambda:** lambda role name is truncated if repo name is too long ([e4f7843](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/e4f7843c0c63894154845106a7b79894feb624e1))

## [0.2.2](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.2.1...v0.2.2) (2025-01-31)


### Bug Fixes

* fixed an error when used with another LW module lambda.zip payload will be used cross modules and cause conflics closes [#4](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/issues/4) ([244ff28](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/244ff28de11f592ad3bdd9d9392597cc179f5071))

## [0.2.1](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.2.0...v0.2.1) (2025-01-31)

## [0.2.0](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/cd304134ce404db0ad3761c9540179725b7edc8d...v0.2.0) (2025-01-30)


### Features

* added codebuild event listener lambda with notifications ([fb728d9](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/fb728d9dc48a4bd4786e8543a2a6d7b45a649d79))
* added variable to append an additional policy document to the codebuild role ([147566b](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/147566b36e81cef6b9e0dddc6c76519376b61eb0))
* first version to test ([cd30413](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/cd304134ce404db0ad3761c9540179725b7edc8d))
* first version with all infrastructure working, TODO fix lambda code and layers ([a70264a](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/a70264a56d2c884f3f93dada81bb433fdcd1d713))
* now paths for SSM parameters can be specified to make the codebuild project read those parameters ([5c43221](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/5c43221414cfaec704c25e790d544aee7010e927))


### Bug Fixes

* **actions:** updated action to make them work on github ([698cee7](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/698cee72b6b7fd82ca37228d3f07a68213edce91))
* fixed some things and added some outputs ([9b2ea38](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/9b2ea382da484e324ab148cb189ac2c356031a9e))
* ignoring .zip files ([afbe2b1](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/afbe2b17dd4a9927724043a16e2cb47257bb04d5))
* **issue template:** fixed name of the issue template dir for github ([b833e61](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/b833e614bb30c9642169fc774ebe78db54f7f599))
* **issue templates:** temporary rename to fix the issue template naming for github ([671e04c](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/671e04c4215155e194271b4eddfef73aac08f8f0))
* minor syntax error in bucket naming ([0735778](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/0735778194638102dc7b8b4dc3ca91b0b3018310))
* **output:** added ssm parameters that the pipeline will need to read ([9d297f8](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/9d297f85b2065ad6f6dee600d673245e219c1e73))
* **output:** fixed error on parameter to read output ([048788c](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/048788ccdf9dacf59c8586c5f04e80440e6f0071))
* restarting package from start ([6786283](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/67862835c4169f8ec75171fea1dae2bd2d3ec1a4))
* restricted codepipeline action to a specific codebuild project, added stopbuild action to permissions ([dd2f8e0](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/dd2f8e006ad193a27d9bbed56229078d77e3a45d))
* updated os version for codebuild environment ([3d0b562](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/3d0b562f24d21aedfee3cde4104f25e01366f2e1))

