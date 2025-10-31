## [2.0.0](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/compare/v1.0.1...v2.0.0) (2025-09-18)


### ⚠ BREAKING CHANGES

* update to AWS V6

### Features

* **ecr:** now image mutability can be chosen even with exclusions closes [#38](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/issues/38) ([c843ef7](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/c843ef7f42f6dae38e94bb1eb4c75c7addde72b6))
* **ssm:** parameters to read can now include wildcard paths closes [#35](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/issues/35) ([721bebb](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/721bebbdf0323622b0b34f06ea3e35a0d1b7a147))
* update to AWS V6 ([a4a3c73](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/a4a3c7325d1602e88cc59a5ee938155def8776ed))


### Bug Fixes

* added providers version constraints in module [#39](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/issues/39) ([fe75a4e](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/fe75a4eef338087d8adb8321322d8e2ee0873609))
* **examples:** fixed reference in outputs ([66640d3](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/66640d31ef67917cd81160233ba45ab4a50a193d))
* **gitignore:** ignoring lock.hcl ([0020d34](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/0020d34a5ada53f1dd2c5abf09a4ca5287f6fc20))
* ignoring .terraform.locl.hcl from now on to prevent restriction on version imposed by this module [#39](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/issues/39) ([dcf5899](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/dcf58999ff8c7f6810fe1007c7635fbf73ffc4b5))
* put restriction on provider, mainly for major/minor version [#39](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/issues/39) ([dc1a30c](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/dc1a30c2e3c2af28e40f029e63d1685aa4758fa8))

## [1.0.1](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/compare/v1.0.0...v1.0.1) (2025-07-28)


### Bug Fixes

* **sns:** corretta issue lunghezza DisplayName closes [#36](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/issues/36) ([3692dcd](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/3692dcd7974098c3e8e881f7a980b72cc7d26e8d))
* solved lifecycle policy creation on new ECR registry ([2db2b14](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/2db2b14191ed1171d7111c721f55a8dff9eea9a5))

## [1.0.0](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/compare/v0.7.1...v1.0.0) (2025-05-20)


### ⚠ BREAKING CHANGES

* **ecr:** now ECR policies don't remove production images, you can specify different pattern to keep different kind of tags closes #32

### Features

* **ecr:** now ECR policies don't remove production images, you can specify different pattern to keep different kind of tags closes [#32](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/issues/32) ([3a67e58](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/commit/3a67e5841f0efc0151a35fda6ef2e30efc8f35a3))

## [0.7.1](https://github.com/Longwave-innovation/terraform-aws-gitops-updater/compare/v0.7.0...v0.7.1) (2025-03-13)

