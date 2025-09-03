output "cloudfront_domain_name" {
  description = "The CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}


output "s3_bucket_name" {
  description = "The name of the S3 bucket created"
  value       = aws_s3_bucket.site_bucket.id
}


output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.cloudfront_waf.arn
}