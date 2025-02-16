## [0.2.6](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.2.5...v0.2.6) (2025-02-16)


### Bug Fixes

* **lambda:** fixed function name length passed to cloudwatch event target ([a178f31](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/a178f31d407509b81a2e5c8d15ed8785a4da7edb))

## [0.2.5](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.2.4...v0.2.5) (2025-02-16)


### Bug Fixes

* fixed target_id length passed to cloudwatch event target ([63b2651](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/63b2651c2be10f2ba20ca73b4ab6e8ab96a6ab25))

## [0.2.4](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.2.3...v0.2.4) (2025-02-16)


### Bug Fixes

* now the same suffix is used on all resources and all nameprefixes are valued correctly closes [#7](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/issues/7) closes [#8](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/issues/8) ([6baef40](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/6baef4097afc1d2e4b830ff11f239592873f7cf1))

## [0.2.3](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.2.2...v0.2.3) (2025-02-16)


### Bug Fixes

* **lambda:** lambda role name is truncated if repo name is too long ([e4f7843](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/e4f7843c0c63894154845106a7b79894feb624e1))

## [0.2.2](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.2.1...v0.2.2) (2025-01-31)


### Bug Fixes

* fixed an error when used with another LW module lambda.zip payload will be used cross modules and cause conflics closes [#4](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/issues/4) ([244ff28](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/244ff28de11f592ad3bdd9d9392597cc179f5071))

