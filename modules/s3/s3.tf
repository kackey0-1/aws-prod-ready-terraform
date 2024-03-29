resource "aws_s3_bucket" "private" {
  bucket = "private-hypo-driven-terraform"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "for_private" {
  bucket = aws_s3_bucket.private.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "for_private" {
  bucket = aws_s3_bucket.private.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "public" {
  bucket = "public-hypo-driven-terraform"
}

resource "aws_s3_bucket_acl" "for_public" {
  bucket = aws_s3_bucket.public.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "for_public" {
  bucket = aws_s3_bucket.public.bucket

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*", "https://static.hypo-driven.com"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-hypo-driven-terraform"
}

resource "aws_s3_bucket_lifecycle_configuration" "for_alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  rule {
    id = "rule-1"
    expiration {
      days = 90
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect = "Allow"
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      identifiers = ["582318560864"]
      type = "AWS"
    }
  }
}

output "access_log_bucket_id" {
  value = aws_s3_bucket.alb_log.id
}
