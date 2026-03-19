# ============================================
# S3 BUCKET — hosts your frontend website
# The bucket name must be globally unique
# so we add your account ID to it
# ============================================
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${data.aws_caller_identity.current.account_id}"

  tags = { Project = var.project_name }
}

# ============================================
# GET CURRENT AWS ACCOUNT INFO
# Used above to make bucket name unique
# ============================================
data "aws_caller_identity" "current" {}

# ============================================
# MAKE THE BUCKET PUBLIC
# Required for static website hosting —
# anyone can visit the website
# ============================================
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ============================================
# BUCKET POLICY — allows public to READ files
# Only GET (read) is allowed — nobody can
# upload or delete via the web
# ============================================
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

# ============================================
# ENABLE STATIC WEBSITE HOSTING
# index.html = the homepage
# ============================================
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document { suffix = "index.html" }
  error_document { key    = "index.html" }
}