# Sanitizing the name is not required anymore, it is preferred to throw an error
# instead of faking a creation a "maybe" not functioning pipeline

locals {
  registry_name = var.ecr_custom_registry_name != "" ? var.ecr_custom_registry_name : var.repo_name
  registry_arn  = var.ecr_use_existing ? data.aws_ecr_repository.existing[0].arn : aws_ecr_repository.registry[0].arn
  registry_url  = var.ecr_use_existing ? data.aws_ecr_repository.existing[0].repository_url : aws_ecr_repository.registry[0].repository_url

  mutability_exclusion_tags = (
    var.parallel_multiplatform_build_enabled ?
    concat(var.ecr_mutability_exclusion_filters, [local.arm64_cache_tag, local.amd64_cache_tag])
    : var.ecr_mutability_exclusion_filters
  )
}

resource "aws_ecr_repository" "registry" {
  count                = var.ecr_use_existing ? 0 : 1
  name                 = local.registry_name
  image_tag_mutability = upper(var.ecr_image_tag_mutability)
  force_delete         = var.force_delete_registry
  image_scanning_configuration {
    scan_on_push = var.ecr_scan_images_on_push
  }

  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = toset(local.mutability_exclusion_tags)
    content {
      filter      = image_tag_mutability_exclusion_filter.value
      filter_type = "WILDCARD"
    }
  }
}

data "aws_ecr_repository" "existing" {
  count = var.ecr_use_existing ? 1 : 0
  name  = local.registry_name
}

data "aws_ecr_lifecycle_policy_document" "policy" {
  rule {
    # High priority for production tagged images
    priority    = 3
    description = "Keep last ${var.ecr_max_prod_tagged_images} production tagged images"

    selection {
      tag_status       = "tagged"
      tag_pattern_list = var.ecr_prod_tag_pattern_list
      count_type       = "imageCountMoreThan"
      count_number     = var.ecr_max_prod_tagged_images
    }
  }

  rule {
    # Medium priority for production tagged images
    priority    = 2
    description = "Keep last ${var.ecr_max_dev_tagged_images} production tagged images"

    selection {
      tag_status       = "tagged"
      tag_pattern_list = var.ecr_dev_tag_pattern_list
      count_type       = "imageCountMoreThan"
      count_number     = var.ecr_max_dev_tagged_images
    }
  }

  rule {
    # LOW priority for production tagged images
    priority    = 1
    description = "Keep last ${var.ecr_max_untagged_images} untagged images"

    selection {
      tag_status   = "untagged"
      count_type   = "imageCountMoreThan"
      count_number = var.ecr_max_untagged_images
    }
  }
}

data "aws_iam_policy_document" "ecr_ext_access" {
  count = length(var.ecr_external_access_arns) > 0 ? 1 : 0
  statement {
    principals {
      identifiers = var.ecr_external_access_arns
      type        = "AWS"
    }
    sid    = "Allow access to ECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings"
    ]
  }
}

resource "aws_ecr_repository_policy" "external_access" {
  count      = length(var.ecr_external_access_arns) > 0 ? 1 : 0
  policy     = data.aws_iam_policy_document.ecr_ext_access[0].json
  repository = local.registry_name
}

resource "aws_ecr_lifecycle_policy" "images_lifecycle" {
  depends_on = [
    data.aws_ecr_repository.existing,
    aws_ecr_repository.registry
  ]
  count      = ((var.ecr_use_existing && var.ecr_override_lifecycle_policy) || !var.ecr_use_existing) ? 1 : 0
  repository = local.registry_name
  policy     = data.aws_ecr_lifecycle_policy_document.policy.json
}
