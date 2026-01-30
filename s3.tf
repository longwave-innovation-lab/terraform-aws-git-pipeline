locals {
  original_name = "${var.repo_owner}-${var.repo_name}-artifact-bucket"

  sanitized_name = lower(
    substr(
      replace(
        replace(
          replace(local.original_name, "/[^a-zA-Z0-9-]/", "-"),
          "/-+/", "-"
        ),
        "/^-|-$/", ""
      ),
      0,
      min(length(replace(replace(replace(local.original_name, "/[^a-zA-Z0-9-]/", "-"), "/-+/", "-"), "/^-|-$/", "")), 37)
    )
  )
}
resource "aws_s3_bucket" "pipeline_artifact_bucket" {
  bucket_prefix = local.sanitized_name
  force_destroy = true # Since is a bucket for artifacts, we can destroy it if needed
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.pipeline_artifact_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
