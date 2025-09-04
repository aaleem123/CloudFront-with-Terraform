
<img width="735" height="630" alt="Screenshot 2025-09-03 212649" src="https://github.com/user-attachments/assets/ac4e5de3-9c6b-4296-a945-2201b6b87c49" />

## CloudFront + S3 project with Terraform

This Terraform project provisions a secure and scalable static website hosting setup using:

- Amazon S3 (for static web content)
- CloudFront CDN (for global distribution)
- AWS WAF (for Layer 7 security)
- OAC (Origin Access Control) (recommended modern method over OAI)
- Terraform for full infrastructure as code

## ✅ Prerequisites

Before running this project, ensure you have the following tools and configurations set up:

- AWS CLI – for managing AWS resources from the terminal: aws configure to log in as your user with AWS Access Key ID and AWS Secret Access Key.
- Terraform – for Infrastructure as Code: download latest version of Terraform
- Git – for version control and pushing to GitHub: configure github once


## ✅ What This Project Does

- Creates an S3 bucket to host static files (`index.html`, `script.js`, `styles.css`)
- Uploads website files to the bucket automatically via Terraform
- Creates a CloudFront distribution with global edge locations for fast content delivery
- Configures OAC (Origin Access Control) to allow CloudFront access to S3 securely
- Integrates AWS WAF to provide protection against common threats
- Protects S3 with a bucket policy to deny public access and allow CloudFront only
- Uses Terraform to automate the entire setup


## 🛡️ What is Origin Access Control (OAC)?

- OAC is a CloudFront feature that securely connects CloudFront to your S3 bucket without exposing the bucket publicly.
- With OAC, only your CloudFront distribution can access your S3 content, making your architecture more secure.


## 🔒 How WAF Works With CloudFront

While WAF is part of the CloudFront ecosystem, it acts like the first security checkpoint before any traffic reaches CloudFront or your content.

- WAF is used to inspect and filter HTTP requests.
- Even though it's managed under CloudFront scope, WAF intercepts requests first.
- This project adds rules for:
  - Bot protection
  - IP reputation filtering
  - Anonymous IP blocking
  - Geo-based rate limiting

## 🔐 Key Security Features

- S3 Bucket is private, no public access allowed.
- OAC ensures only CloudFront can fetch objects from S3.
- WAF applies AWS-managed rules + custom geo rate limiting to protect the app from:
  ⦁	Bad bots
  ⦁	Anonymous or malicious IPs
  ⦁	Suspicious IP reputation
  ⦁	Specific countries (geo block)


## ⚠️ What went wrong
We had error 
**WAFInvalidParameterException: The ARN isn't valid.**
The reason for this error is Regional and Global scope entities:
**Global**:<br>
- WAF Web ACL with a CloudFront distribution: Use web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn directly in the aws_cloudfront_distribution resource in main.tf<br>
- Set the WAF region to us-east-1
**Regional**:<br>
- WAF Web ACL with ALB / API Gateway / AppSync: Use aws_wafv2_web_acl_association block in waf.tf resource 

<img width="1919" height="996" alt="Screenshot 2025-09-04 162747" src="https://github.com/user-attachments/assets/69c349e6-a2b9-4ea1-ae1d-991ea625be96" />

<img width="1919" height="1001" alt="Screenshot 2025-09-04 162759" src="https://github.com/user-attachments/assets/54bfa827-90f4-4293-a653-18b0e1159ac6" />

<img width="1919" height="1005" alt="Screenshot 2025-09-04 162810" src="https://github.com/user-attachments/assets/3e928718-6566-4d53-a101-5d90f2ddee21" />


