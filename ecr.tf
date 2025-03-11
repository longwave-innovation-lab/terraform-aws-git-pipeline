# Sanitizing the name is not required anymore, it is preferred to throw an error 
# instead of faking a creation a "maybe" not functioning pipeline

locals {
  registry_name = var.ecr_custom_registry_name != "" ? var.ecr_custom_registry_name : var.repo_name
  registry_arn  = var.ecr_use_existing ? data.aws_ecr_repository.existing[0].arn : aws_ecr_repository.registry[0].arn
  registry_url  = var.ecr_use_existing ? data.aws_ecr_repository.existing[0].repository_url : aws_ecr_repository.registry[0].repository_url
}

resource "aws_ecr_repository" "registry" {
  count                = var.ecr_use_existing ? 0 : 1
  name                 = local.registry_name
  image_tag_mutability = "MUTABLE"
  force_delete         = var.force_delete_registry
  image_scanning_configuration {
    scan_on_push = var.scan_images_on_push
  }
}

data "aws_ecr_repository" "existing" {
  count = var.ecr_use_existing ? 1 : 0
  name  = local.registry_name
}

resource "aws_ecr_lifecycle_policy" "images_lifecycle" {
  repository = local.registry_name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 2,
            "description": "Keep last ${var.ecr_tagged_images_to_keep} images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.ecr_tagged_images_to_keep}
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 1,
            "description": "Keep only one untagged image maximum",
            "selection": {
                "tagStatus": "untagged",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.ecr_untagged_images_to_keep}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
