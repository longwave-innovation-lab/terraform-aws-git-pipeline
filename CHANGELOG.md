## [2.0.0](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/compare/v1.0.1...v2.0.0) (2026-04-10)


### ⚠ BREAKING CHANGES

* Codecommit filtering works, path are glob patterns, unit testing closes, changed name of path filter variable #11

### Features

* Codecommit filtering works, path are glob patterns, unit testing closes, changed name of path filter variable [#11](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/11) ([26640a7](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/26640a76497cdd76e77a60f2df561a5a8f4b8e2e))
* codecommit path filter first draft [#11](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/11) ([398897d](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/398897dcc5ae238b1761f7f8fd3e9d172b9b774a))


### Bug Fixes

* **ci:** mdlint now wait for doctoc to run ([7a1d831](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/7a1d8319183f2f7635f8104e5eaf66a2df369f0a))

## [1.0.1](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/compare/v1.0.0...v1.0.1) (2026-03-23)


### Bug Fixes

* removed wrong condition on source stage that was overriding pr changes ([7a6cf3a](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/7a6cf3a1a78ec626b3e773ce249a756e05c71e57))

## [1.0.0](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/compare/v0.1.5...v1.0.0) (2026-03-23)


### ⚠ BREAKING CHANGES

* now codepipeline_type must be uppercase, defualt is V2

### Bug Fixes

* now codepipeline_type must be uppercase, defualt is V2 ([e87fdbd](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/e87fdbd1a59a2f08dabdaa725bd51d3bf1a35e9d))

## [0.1.5](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/compare/v0.1.4...v0.1.5) (2026-03-23)


### Bug Fixes

* correctly updated the stage source name to match the trigger block and prevent error on create, whether V2 or V1 is used ([f57b769](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/f57b76948d6d719703c09e8b5fc798d065780cf6))
* fix version source example readme.md ([1ee40ba](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/1ee40ba3540300a2979f7dbe4106c691e39fce07))
* removing .lock.hcl files that prevents cache plugin dir to be used ([5f3d80b](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/5f3d80b73f3a6ee473ccce3143170101642e2314))
* source url example readme.md ([1dc4bb2](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/1dc4bb2acf34d344272021120317ec3d1e8636c7))
* using pipeline V2 won't give error with multi source ([a796916](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/a796916257e570514b17af416d639d1ebc1b9cd1))

## [0.1.4](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/compare/v0.1.3...v0.1.4) (2026-03-20)


### Bug Fixes

* using pipeline V2 won't give error with multi source ([77812b7](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/77812b79f02025c8aa680a3e64d75ad564e78348))

