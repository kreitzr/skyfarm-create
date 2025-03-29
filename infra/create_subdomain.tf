provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  profile = "skyfarmstudios-dev"
}

resource "aws_acm_certificate" "create_subdomain_cert" {
  provider          = aws.us_east_1
  domain_name       = "create.skyfarmstudios.com"
  validation_method = "DNS"

  tags = {
    Name = "ComfyUI Create Subdomain Cert"
    Env  = "dev"
  }
}

# Output instructions to manually validate the domain in Google Domains
output "acm_dns_validation_name" {
  value = element(aws_acm_certificate.create_subdomain_cert.domain_validation_options[*].resource_record_name, 0)
}

output "acm_dns_validation_value" {
  value = element(aws_acm_certificate.create_subdomain_cert.domain_validation_options[*].resource_record_value, 0)
}

output "acm_dns_validation_type" {
  value = element(aws_acm_certificate.create_subdomain_cert.domain_validation_options[*].resource_record_type, 0)
}

# Create a new CloudFront distribution using custom domain and the existing S3 bucket
resource "aws_cloudfront_distribution" "create_subdomain_cdn" {
  enabled             = true
  default_root_object = "index.html"

  aliases = ["create.skyfarmstudios.com"]

  origin {
    domain_name = aws_s3_bucket_website_configuration.static_site.website_endpoint
    origin_id   = "S3Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.create_subdomain_cert.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "Create Subdomain CDN"
    Env  = "dev"
  }

  depends_on = [aws_acm_certificate.create_subdomain_cert]
}

output "cloudfront_custom_domain_url" {
  value = aws_cloudfront_distribution.create_subdomain_cdn.domain_name
}
