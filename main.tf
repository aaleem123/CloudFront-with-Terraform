locals {
  static_files = {
    "index.html" = "text/html"
    "script.js"  = "application/javascript"
    "styles.css" = "text/css"
  }
}

resource "aws_s3_bucket" "site_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = "StaticSiteBucket"
  }
}

resource "aws_s3_bucket_public_access_block" "block_all" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront automatically uses global edge locations
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html" #whats needs to be hit
  wait_for_deployment = true

  origin {
    domain_name = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.site_bucket.bucket

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    #cache_policy_id = u can set this, if not a default is used
    target_origin_id = aws_s3_bucket.site_bucket.bucket

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Using default CloudFront TLS cert; replace with ACM cert for custom domain (we dont have custom domain right now)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" #block or allow some countries
    }
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn

  tags = {
    Name = "StaticSiteCDN"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.site_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontAccessOnly",
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.site_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_object" "website_assets" {
  for_each     = local.static_files
  bucket       = aws_s3_bucket.site_bucket.id
  key          = each.key
  source       = "./website/${each.key}"
  content_type = each.value
}

