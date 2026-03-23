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

## [0.1.3](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/compare/v0.1.2...v0.1.3) (2026-03-04)


### Bug Fixes

* fix example module git pipeline -2 ([b9e2982](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/b9e29825a4036361b770a6740d81383b9e55bdd0))

