resource "aws_s3_bucket" "mac_binaries" {
  bucket        = "mac.assets.tyk"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "mac_binaries" {
  bucket                  = aws_s3_bucket.mac_binaries.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "mac_binaries" {
  bucket = aws_s3_bucket.mac_binaries.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.mac_binaries.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.mac_binaries.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_control" "mac_binaries" {
  name                              = "s3-oac"
  description                       = "OAC for accessing mac binaries"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.mac_binaries.bucket_regional_domain_name
    origin_id   = "s3-mac-binaries"
    origin_access_control_id = aws_cloudfront_origin_access_control.mac_binaries.id
  }
  enabled = true
  is_ipv6_enabled = true
  default_cache_behavior {
    allowed_methods        = [ "GET", "HEAD" ]
    cached_methods         = [ "GET", "HEAD" ]
    target_origin_id       = "s3-mac-binaries"
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  tags = {
    "name"    = "mac-binaries-cdn",
    "managed" = "terraform"
  }
}