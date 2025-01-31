# Sanitizing the name is not required anymore, it is preferred to throw an error 
# instead of faking a creation a "maybe" not functioning pipeline
resource "aws_ecr_repository" "registry" {
  name                 = var.repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = var.force_delete_registry
  image_scanning_configuration {
    scan_on_push = var.scan_images_on_push
  }
}

resource "aws_ecr_lifecycle_policy" "images_lifecycle" {
  repository = aws_ecr_repository.registry.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 2,
            "description": "Keep last ${var.images_to_keep} images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.images_to_keep}
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
                "countNumber": 1
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}