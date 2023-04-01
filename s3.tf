resource "aws_s3_bucket" "backend" {
  bucket = "vo-tf-bucket" #globally unique
}

# S3 Version Control
resource "aws_s3_bucket_versioning" "backend" {
  bucket = aws_s3_bucket.backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 resource bucket policy
data "aws_iam_policy_document" "backend" {
  statement {
    sid = "Public View"
    principals {
      type        = "AWS"
      identifiers = [ "*" ]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.backend.arn, "${aws_s3_bucket.backend.arn}/*"
    ]
  }
}

# Attach Policy
resource "aws_s3_bucket_policy" "backend" {
  bucket = aws_s3_bucket.backend.id
  policy = data.aws_iam_policy_document.backend.json
}