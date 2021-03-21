provider "aws" {
    region = var.state_region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket
  lifecycle {
    #  prevent_destroy = true
    prevent_destroy = false
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  object_lock_configuration {
    object_lock_enabled = "Enabled"
  }
	acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_region" {
	value = aws_s3_bucket.terraform_state.region
	description = "Region for saving terraform state"
}

output "state_bucket" {
	value = aws_s3_bucket.terraform_state.bucket
	description = "Bucket for saving terraform state"
}
