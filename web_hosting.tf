resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

data "aws_iam_user" "devops_user" {
  user_name = var.devops_user_name
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.domain
  acl    = "public-read"
  policy = data.aws_iam_policy_document.bucket_policy.json

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = local.common_tags
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${var.domain}/*"]
  }

  statement {
    sid    = "DevOpsUserGetBucket"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.devops_user.arn]
    }
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${var.domain}"]
  }

  statement {
    sid    = "DevOpsUserGetPutObject"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.devops_user.arn]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::${var.domain}/*"]
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    origin_id   = var.domain
    domain_name = aws_s3_bucket.bucket.website_endpoint

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # If using route53 aliases for DNS we need to declare it here too, otherwise we'll get 403s.
  aliases = [var.domain]

  enabled             = true
  default_root_object = "index.html"

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = 0
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.domain

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # The cheapest priceclass
  price_class = "PriceClass_100"

  # This is required to be specified even if it's not used.
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.web.certificate_arn
    minimum_protocol_version = "TLSv1.2_2019"
    ssl_support_method       = "sni-only"
  }

  tags = local.common_tags
}

// To use an ACM certificate with Amazon CloudFront, you must request or import the certificate in the US East (N. Virginia) region.
// https://docs.aws.amazon.com/acm/latest/userguide/acm-regions.html
resource "aws_acm_certificate" "web" {
  provider          = aws.us
  domain_name       = var.domain
  validation_method = "DNS"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "web" {
  provider                = aws.us
  certificate_arn         = aws_acm_certificate.web.arn
  validation_record_fqdns = [for record in aws_route53_record.web_validation : record.fqdn]
}

resource "aws_route53_record" "web_validation" {
  for_each = {
    for dvo in aws_acm_certificate.web.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}
