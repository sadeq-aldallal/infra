resource "aws_s3_bucket" "shops_fead" {
  bucket = "${var.env}-${var.product}-shops"

  tags = {
    Env = "${var.env}"
  }
}

# Define public access block settings for the bucket
resource "aws_s3_bucket_public_access_block" "shops_fead_public_access_block" {
  bucket = aws_s3_bucket.shops_fead.id

  block_public_acls       = true
  block_public_policy     = false  # Allow public policies to be set
  ignore_public_acls      = true
  restrict_public_buckets = false  # Don't restrict public bucket access
}

# Bucket policy to allow public read access to objects
resource "aws_s3_bucket_policy" "shops_fead_policy" {
  bucket = aws_s3_bucket.shops_fead.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.shops_fead.arn}/*"
      }
    ]
  })
}
