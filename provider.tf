terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Extra AWS provider alias for CLOUDFRONT-scoped WAF (must always be us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "time" {}
