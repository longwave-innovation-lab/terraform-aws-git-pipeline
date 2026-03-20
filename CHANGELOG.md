## [0.1.3](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/compare/v0.1.2...v0.1.3) (2026-03-04)


### Bug Fixes

* fix example module git pipeline -2 ([b9e2982](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/b9e29825a4036361b770a6740d81383b9e55bdd0))

## [0.1.2](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/compare/v0.1.1...v0.1.2) (2026-03-04)


### Bug Fixes

* fix example module git pipeline ([6263cbd](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/6263cbd40833579936879a8ee7778ba2dbf452a2))

## [0.1.1](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/compare/v0.1.0...v0.1.1) (2026-02-03)


### Bug Fixes

* manual approval info are now correct with CodeCommit closes [#2](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/2) ([866c42b](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/866c42b3f9a0acea0a498d9d1c4ec4be6b6bbc0b))

## [0.1.0](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/compare/cd304134ce404db0ad3761c9540179725b7edc8d...v0.1.0) (2026-01-30)


### ⚠ BREAKING CHANGES

* enabled support for Codecommit and other git providers. Some resources will change names beware
* update to AWS V6
* update to AWS V6
* **ecr:** now ECR policies don't remove production images, you can specify different pattern to keep different kind of tags closes #32

### Features

* adapted custom registry name in sns notifics closes [#23](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/23) ([8daacd9](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/8daacd935d751aed6c2865c84c715c54d31825bd))
* added codebuild event listener lambda with notifications ([fb728d9](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/fb728d9dc48a4bd4786e8543a2a6d7b45a649d79))
* added parameter to change max number or un-tagged images in registry ([d2c8f10](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/d2c8f103e6943004e9e7fca4ffc34f14e9a86751))
* added path filter to decide when to trigger closes [#16](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/16) added codepipeline type variable ([9c59a7a](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/9c59a7aeda6bc32a8a31ba1ab07c77591b4614b4))
* added variable to add custom environment variables to CodeBuild closes [#26](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/26) ([71102d8](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/71102d89f4a42cd6248a0f459ddfd15b65c62a60))
* added variable to append an additional policy document to the codebuild role ([147566b](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/147566b36e81cef6b9e0dddc6c76519376b61eb0))
* **ecr:** added external access repository policy closes [#43](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/43) ([32ca678](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/32ca67801d2e9e4590b8689b96d10901c2b6fdb1))
* **ecr:** custom registry name closes [#21](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/21) ([e9cb983](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/e9cb9838ff5dd22662ee9546b9fc52ba1a842ffc))
* **ecr:** now ECR policies don't remove production images, you can specify different pattern to keep different kind of tags closes [#32](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/32) ([3a67e58](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/3a67e5841f0efc0151a35fda6ef2e30efc8f35a3))
* **ecr:** now image mutability can be chosen even with exclusions closes [#38](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/38) ([c843ef7](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/c843ef7f42f6dae38e94bb1eb4c75c7addde72b6))
* **ecr:** now image mutability can be chosen even with exclusions closes [#38](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/38) ([1fcf53a](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/1fcf53aaf1499301f66ac86d08b39d5e35b0499a))
* enabled support for Codecommit and other git providers. Some resources will change names beware ([ca05f4c](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/ca05f4c11d86834e2d13d11c848a15d0fa327bb4))
* first version to test ([cd30413](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/cd304134ce404db0ad3761c9540179725b7edc8d))
* first version with all infrastructure working, TODO fix lambda code and layers ([a70264a](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/a70264a56d2c884f3f93dada81bb433fdcd1d713))
* implemented manual approval closes [#13](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/13) and use of existing ecr closes [#15](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/15) ([b83ee6f](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/b83ee6f8686fa0396aa9579e76192d7ea7a30dd0))
* now multiplatform can be done in parallel instances closes [#42](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/42) ([f19cf00](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/f19cf007017d132f23b6e8521508088b108cd245))
* now paths for SSM parameters can be specified to make the codebuild project read those parameters ([5c43221](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/5c43221414cfaec704c25e790d544aee7010e927))
* **ssm:** parameters to read can now include wildcard paths closes [#35](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/35) ([721bebb](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/721bebbdf0323622b0b34f06ea3e35a0d1b7a147))
* **ssm:** parameters to read can now include wildcard paths closes [#35](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/35) ([b4c205a](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/b4c205a63da4570aefc2ac7e4067fd824c965412))
* update to AWS V6 ([a4a3c73](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/a4a3c7325d1602e88cc59a5ee938155def8776ed))
* update to AWS V6 ([6c92814](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/6c928147a712134f2a4caa3e5e4dcd1f705d356c))


### Bug Fixes

* **action:** added command to move back to repo dir ([4279715](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/427971578aabb11675e491d462379acf0836edea))
* **action:** added command to move back to repo dir ([83462e0](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/83462e06385ade5f05b1c4fbd1ca62eae53764d3))
* **action:** changed tf docs recursive direcotory name ([fcad2ac](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/fcad2ac1847350c9a02623796c70a4f15edad440))
* **action:** fixed tf docs config file syntax ([f6ead71](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/f6ead7191eee1be7f6210344c598bfa2343df354))
* **action:** make action retrigger upon changes ([2063e18](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/2063e189e51c99ebeb32fcb1df4b9e8e6c84f6d0))
* **action:** rolled back documentation action and re-enabled terraform docs ([2394522](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/2394522a3ad102b1fc3085439c549dab6b679526))
* **actions:** updated action to make them work on github ([698cee7](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/698cee72b6b7fd82ca37228d3f07a68213edce91))
* **actions:** updated doc and toc action ([ad9f75e](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/ad9f75e8663d055b1510f38239fe4a782dbd2bd2))
* **action:** testing tf docs action ([5fa7300](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/5fa7300ed915520f04f55bf1c695b8600615e3c3))
* **action:** updated doc action triggers ([2d35d2b](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/2d35d2b1be4821199f3b85b9c27a99b2fa2977ee))
* **action:** updated tf docs action ([d93151e](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/d93151e31b772907a7e24abaf3d68c00fb2c028b))
* added providers version constraints in module [#39](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/39) ([fe75a4e](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/fe75a4eef338087d8adb8321322d8e2ee0873609))
* added providers version constraints in module [#39](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/39) ([f7963a6](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/f7963a6d6e52b91a1f507d37032331696e1b04a1))
* added repo org shortname to prevend naming problems on long names closes [#18](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/18) ([604b4c4](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/604b4c4b4f1d063f45c5218426c8563977c05650))
* changed default amazonlinux container image for codebuild to use the proper alias ([f32ca68](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/f32ca68cc043cfe79e9975dfbc0886dcc6e316ec))
* changed default value for repo org shortname ([b4d2110](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/b4d21105a489222aea8d23c92246e35b2ab99067))
* changed name of codepipeline pipeline to be more standard ([bc8b87c](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/bc8b87cbc086fcc41f6d46ef76c17b27b381abc3))
* **cicd:** added exception to markdown lint ([868d7f7](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/868d7f790b2e1bc6d5542ffae9f254a610aec9aa))
* **cicd:** release action updated according to lw template standard ([c6b1d84](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/c6b1d8489101f3d899b4b918d00d26cf2dcef9e4))
* **cicd:** removed package.json since is not needed ([47d5f5b](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/47d5f5ba09a87e2cc05eaafea31abe473824ffbc))
* **cicd:** updated documentation action ([33ccc43](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/33ccc439d23407cc24e220ffa73476f3d89d3b92))
* **examples:** fixed reference in outputs ([66640d3](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/66640d31ef67917cd81160233ba45ab4a50a193d))
* **examples:** fixed reference in outputs ([0309ac8](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/0309ac8ebe5901b417d742dafd06cba0a93ce641))
* fixed an error when used with another LW module lambda.zip payload will be used cross modules and cause conflics closes [#4](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/4) ([244ff28](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/244ff28de11f592ad3bdd9d9392597cc179f5071))
* fixed codebuild project logs permission arn ([dfab8cf](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/dfab8cf8aa6316dbce36604378bf53afe8b8912a))
* fixed naming issue adding branch name in resources names ([411993e](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/411993e61b8f0106b1ccf4ee1e280a00fbaf4c7c))
* fixed some things and added some outputs ([9b2ea38](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/9b2ea382da484e324ab148cb189ac2c356031a9e))
* fixed target_id length passed to cloudwatch event target ([63b2651](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/63b2651c2be10f2ba20ca73b4ab6e8ab96a6ab25))
* **gitignore:** ignoring lock.hcl ([0020d34](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/0020d34a5ada53f1dd2c5abf09a4ca5287f6fc20))
* **gitignore:** ignoring lock.hcl ([8cbc1c2](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/8cbc1c20a212f2f669ddba8c059425b22d53d260))
* ignoring .terraform.locl.hcl from now on to prevent restriction on version imposed by this module [#39](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/39) ([dcf5899](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/dcf58999ff8c7f6810fe1007c7635fbf73ffc4b5))
* ignoring .terraform.locl.hcl from now on to prevent restriction on version imposed by this module [#39](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/39) ([6131c47](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/6131c479673adfff99dcc857bf146fec9a201c4d))
* ignoring .zip files ([afbe2b1](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/afbe2b17dd4a9927724043a16e2cb47257bb04d5))
* **issue template:** fixed name of the issue template dir for github ([b833e61](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/b833e614bb30c9642169fc774ebe78db54f7f599))
* **issue templates:** temporary rename to fix the issue template naming for github ([671e04c](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/671e04c4215155e194271b4eddfef73aac08f8f0))
* **lambda:** fixed function name length passed to cloudwatch event target ([a178f31](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/a178f31d407509b81a2e5c8d15ed8785a4da7edb))
* **lambda:** lambda role name is truncated if repo name is too long ([e4f7843](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/e4f7843c0c63894154845106a7b79894feb624e1))
* minor syntax error in bucket naming ([0735778](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/0735778194638102dc7b8b4dc3ca91b0b3018310))
* now the same suffix is used on all resources and all nameprefixes are valued correctly closes [#7](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/7) closes [#8](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/8) ([6baef40](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/6baef4097afc1d2e4b830ff11f239592873f7cf1))
* **output:** added ssm parameters that the pipeline will need to read ([9d297f8](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/9d297f85b2065ad6f6dee600d673245e219c1e73))
* **output:** fixed error on parameter to read output ([048788c](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/048788ccdf9dacf59c8586c5f04e80440e6f0071))
* put restriction on provider, mainly for major/minor version [#39](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/39) ([dc1a30c](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/dc1a30c2e3c2af28e40f029e63d1685aa4758fa8))
* put restriction on provider, mainly for major/minor version [#39](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/39) ([2b8642a](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/2b8642ad44e3253d4e6fb7f9eff3db976dc19573))
* restarting package from start ([6786283](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/67862835c4169f8ec75171fea1dae2bd2d3ec1a4))
* restricted codepipeline action to a specific codebuild project, added stopbuild action to permissions ([dd2f8e0](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/dd2f8e006ad193a27d9bbed56229078d77e3a45d))
* sns notifications give more info in parallel codepipeline [#42](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/42) ([52ec016](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/52ec016059500e5ab074fd141aac5b61eb579b57))
* **sns:** corretta issue lunghezza DisplayName closes [#36](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/36) ([3692dcd](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/3692dcd7974098c3e8e881f7a980b72cc7d26e8d))
* solved lifecycle policy creation on new ECR registry ([2db2b14](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/2db2b14191ed1171d7111c721f55a8dff9eea9a5))
* **tf docs:** enabled recursive updates on example dir ([8cfe65a](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/8cfe65a628717992894f49d5df4f0a90ec10bb29))
* updated default codepipeline policy closes [#30](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/issues/30) ([b39b190](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/b39b190519739f720649e70b47dd02fceb5580e7))
* updated example with sample repo ([e3602a7](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/e3602a75f0820e66f2b69ee02a85fa9adcfaf0c7))
* updated os version for codebuild environment ([3d0b562](https://github.com/longwave-innovation-lab/terraform-aws-git-pipeline/commit/3d0b562f24d21aedfee3cde4104f25e01366f2e1))

