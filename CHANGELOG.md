## [1.0.0](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.7.1...v1.0.0) (2025-05-20)


### ⚠ BREAKING CHANGES

* **ecr:** now ECR policies don't remove production images, you can specify different pattern to keep different kind of tags closes #32

### Features

* **ecr:** now ECR policies don't remove production images, you can specify different pattern to keep different kind of tags closes [#32](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/issues/32) ([3a67e58](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/3a67e5841f0efc0151a35fda6ef2e30efc8f35a3))

## [0.7.1](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.7.0...v0.7.1) (2025-03-13)

## [0.7.0](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.6.0...v0.7.0) (2025-03-11)


### Features

* added variable to add custom environment variables to CodeBuild closes [#26](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/issues/26) ([71102d8](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/71102d89f4a42cd6248a0f459ddfd15b65c62a60))

## [0.6.0](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.5.0...v0.6.0) (2025-03-11)


### Features

* adapted custom registry name in sns notifics closes [#23](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/issues/23) ([8daacd9](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/8daacd935d751aed6c2865c84c715c54d31825bd))
* added parameter to change max number or un-tagged images in registry ([d2c8f10](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/d2c8f103e6943004e9e7fca4ffc34f14e9a86751))


### Bug Fixes

* **action:** make action retrigger upon changes ([2063e18](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/2063e189e51c99ebeb32fcb1df4b9e8e6c84f6d0))
* **action:** updated tf docs action ([d93151e](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/d93151e31b772907a7e24abaf3d68c00fb2c028b))

## [0.5.0](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/compare/v0.4.2...v0.5.0) (2025-03-11)


### Features

* **ecr:** custom registry name closes [#21](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/issues/21) ([e9cb983](https://git.lantechlongwave.it/RnD/terraform-aws-github-pipeline/commit/e9cb9838ff5dd22662ee9546b9fc52ba1a842ffc))

