## [3.1.0](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/compare/v3.0.0...v3.1.0) (2026-01-21)


### Features

* now multiplatform can be done in parallel instances closes [#42](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/42) ([f19cf00](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/f19cf007017d132f23b6e8521508088b108cd245))


### Bug Fixes

* changed default amazonlinux container image for codebuild to use the proper alias ([f32ca68](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/f32ca68cc043cfe79e9975dfbc0886dcc6e316ec))
* sns notifications give more info in parallel codepipeline [#42](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/42) ([52ec016](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/52ec016059500e5ab074fd141aac5b61eb579b57))
* updated example with sample repo ([e3602a7](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/e3602a75f0820e66f2b69ee02a85fa9adcfaf0c7))

## [3.0.0](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/compare/v2.0.0...v3.0.0) (2026-01-19)


### ⚠ BREAKING CHANGES

* update to AWS V6

### Features

* **ecr:** added external access repository policy closes [#43](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/43) ([32ca678](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/32ca67801d2e9e4590b8689b96d10901c2b6fdb1))
* **ecr:** now image mutability can be chosen even with exclusions closes [#38](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/38) ([1fcf53a](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/1fcf53aaf1499301f66ac86d08b39d5e35b0499a))
* **ssm:** parameters to read can now include wildcard paths closes [#35](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/35) ([b4c205a](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/b4c205a63da4570aefc2ac7e4067fd824c965412))
* update to AWS V6 ([6c92814](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/6c928147a712134f2a4caa3e5e4dcd1f705d356c))


### Bug Fixes

* added providers version constraints in module [#39](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/39) ([f7963a6](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/f7963a6d6e52b91a1f507d37032331696e1b04a1))
* **cicd:** added exception to markdown lint ([868d7f7](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/868d7f790b2e1bc6d5542ffae9f254a610aec9aa))
* **cicd:** release action updated according to lw template standard ([c6b1d84](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/c6b1d8489101f3d899b4b918d00d26cf2dcef9e4))
* **cicd:** removed package.json since is not needed ([47d5f5b](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/47d5f5ba09a87e2cc05eaafea31abe473824ffbc))
* **cicd:** updated documentation action ([33ccc43](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/33ccc439d23407cc24e220ffa73476f3d89d3b92))
* **examples:** fixed reference in outputs ([0309ac8](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/0309ac8ebe5901b417d742dafd06cba0a93ce641))
* **gitignore:** ignoring lock.hcl ([8cbc1c2](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/8cbc1c20a212f2f669ddba8c059425b22d53d260))
* ignoring .terraform.locl.hcl from now on to prevent restriction on version imposed by this module [#39](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/39) ([6131c47](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/6131c479673adfff99dcc857bf146fec9a201c4d))
* put restriction on provider, mainly for major/minor version [#39](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/39) ([2b8642a](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/2b8642ad44e3253d4e6fb7f9eff3db976dc19573))

## [2.0.0](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/compare/v1.0.1...v2.0.0) (2025-09-18)


### ⚠ BREAKING CHANGES

* update to AWS V6

### Features

* **ecr:** now image mutability can be chosen even with exclusions closes [#38](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/38) ([c843ef7](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/c843ef7f42f6dae38e94bb1eb4c75c7addde72b6))
* **ssm:** parameters to read can now include wildcard paths closes [#35](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/35) ([721bebb](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/721bebbdf0323622b0b34f06ea3e35a0d1b7a147))
* update to AWS V6 ([a4a3c73](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/a4a3c7325d1602e88cc59a5ee938155def8776ed))


### Bug Fixes

* added providers version constraints in module [#39](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/39) ([fe75a4e](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/fe75a4eef338087d8adb8321322d8e2ee0873609))
* **examples:** fixed reference in outputs ([66640d3](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/66640d31ef67917cd81160233ba45ab4a50a193d))
* **gitignore:** ignoring lock.hcl ([0020d34](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/0020d34a5ada53f1dd2c5abf09a4ca5287f6fc20))
* ignoring .terraform.locl.hcl from now on to prevent restriction on version imposed by this module [#39](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/39) ([dcf5899](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/dcf58999ff8c7f6810fe1007c7635fbf73ffc4b5))
* put restriction on provider, mainly for major/minor version [#39](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/39) ([dc1a30c](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/dc1a30c2e3c2af28e40f029e63d1685aa4758fa8))

## [1.0.1](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/compare/v1.0.0...v1.0.1) (2025-07-28)


### Bug Fixes

* **sns:** corretta issue lunghezza DisplayName closes [#36](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/36) ([3692dcd](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/3692dcd7974098c3e8e881f7a980b72cc7d26e8d))
* solved lifecycle policy creation on new ECR registry ([2db2b14](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/2db2b14191ed1171d7111c721f55a8dff9eea9a5))

## [1.0.0](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/compare/v0.7.1...v1.0.0) (2025-05-20)


### ⚠ BREAKING CHANGES

* **ecr:** now ECR policies don't remove production images, you can specify different pattern to keep different kind of tags closes #32

### Features

* **ecr:** now ECR policies don't remove production images, you can specify different pattern to keep different kind of tags closes [#32](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/issues/32) ([3a67e58](https://github.com/Longwave-innovation/terraform-aws-github-pipeline/commit/3a67e5841f0efc0151a35fda6ef2e30efc8f35a3))

