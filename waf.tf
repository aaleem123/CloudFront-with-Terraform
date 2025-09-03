# WAF setup (disabled by default)

resource "aws_wafv2_web_acl" "cloudfront_waf" {
  name  = "wafv2-cloudfront"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesBotControlRuleSet"
    priority = 0

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "geo-rate-limit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"

        scope_down_statement {
          geo_match_statement {
            country_codes = ["US", "NL"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "geo-rate-limit"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "wafv2-cloudfront"
    sampled_requests_enabled   = true
  }
}

# Data source to fetch the CloudFront ARN after creation
# Wait a bit after CloudFront is created/deployed

resource "time_sleep" "after_cloudfront" {
  depends_on      = [aws_cloudfront_distribution.cdn]
  create_duration = "180s"   # increase to 300s if needed
}

# Re-read the distribution AFTER the wait to get a valid, fully-propagated ARN
data "aws_cloudfront_distribution" "cdn" {
  id         = aws_cloudfront_distribution.cdn.id
  depends_on = [time_sleep.after_cloudfront]
}

# Associate WAF to CloudFront using the data source ARN (includes account id)
resource "aws_wafv2_web_acl_association" "cloudfront_waf_assoc" {
  resource_arn = data.aws_cloudfront_distribution.cdn.arn
  web_acl_arn  = aws_wafv2_web_acl.cloudfront_waf.arn

  depends_on = [data.aws_cloudfront_distribution.cdn]

  lifecycle {
    create_before_destroy = true
  }
}



## We have separated WAF into its own file to avoid lifecycle issues.
## You need to add `depends_on` and `lifecycle` blocks to avoid errors, 
## because the `resource_arn` must be dynamically fetched from the CloudFront distribution after it's created.
## CloudFront is a global service, while WAF can be regional or global (for CloudFront, it must be global).
## When Terraform tries to associate the WAF before the CloudFront ARN is fully known, 
## it fails with an "invalid ARN" error.