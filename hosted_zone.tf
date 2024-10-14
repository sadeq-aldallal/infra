resource "aws_route53_zone" "prod" {
  name = "${var.product}.app"

  tags = {
    Env = "prod-${var.product}"
  }
}

resource "aws_route53_zone" "dev" {
  name = "${var.env}.${var.product}.app"

  tags = {
    Env = "${var.env}-${var.product}"
  }
}

resource "aws_route53_record" "dev_ns" {
  zone_id = aws_route53_zone.prod.zone_id
  name    = aws_route53_zone.dev.name
  type    = "NS"
  ttl     = 30
  records = aws_route53_zone.dev.name_servers
}

resource "aws_route53_record" "bsiness_static_website" {
  name    = local.bsiness_static_website_domain
  type    = "A"
  zone_id = aws_route53_zone.dev.id


  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.bsiness_static_website_dev.domain_name
    zone_id                = aws_cloudfront_distribution.bsiness_static_website_dev.hosted_zone_id
  }
}

# Wildcard certs for prod and dev in me-east-1

resource "aws_acm_certificate" "prod" {
  domain_name       = "*.${var.product}.app"
  validation_method = "DNS"

  tags = {
    Env = "${var.env}-${var.product}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "dev" {
  domain_name       = "*.${var.env}.${var.product}.app"
  validation_method = "DNS"

  tags = {
    Env = "${var.env}-${var.product}"
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "prod_cert" {
  zone_id = aws_route53_zone.prod.zone_id
  name    = tolist(aws_acm_certificate.prod.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.prod.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.prod.domain_validation_options)[0].resource_record_value]
  ttl     = 60
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "dev_cert" {
  zone_id = aws_route53_zone.dev.zone_id
  name    = tolist(aws_acm_certificate.dev.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.dev.domain_validation_options)[0].resource_record_type
  records = [tolist(aws_acm_certificate.dev.domain_validation_options)[0].resource_record_value]
  ttl     = 60
    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_acm_certificate_validation" "prod" {
  certificate_arn         = aws_acm_certificate.prod.arn
  validation_record_fqdns = [aws_route53_record.prod_cert.fqdn]
}

resource "aws_acm_certificate_validation" "dev" {
  certificate_arn         = aws_acm_certificate.dev.arn
  validation_record_fqdns = [aws_route53_record.dev_cert.fqdn]
}

# Wildcard certs for prod and dev in us-east-1

resource "aws_acm_certificate" "prod_us" {
  provider          = aws.vir
  domain_name       = "*.${var.product}.app"
  validation_method = "DNS"

  tags = {
    Env = "${var.env}-${var.product}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "dev_us" {
  provider          = aws.vir
  domain_name       = "*.${var.env}.${var.product}.app"
  validation_method = "DNS"

  tags = {
    Env = "${var.env}-${var.product}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
# =========================
# business_dev
# =========================
# resource "aws_acm_certificate" "business_dev" {
#   provider          = aws.vir
#   domain_name       = "business.${var.env}.${var.product}.app"
#   validation_method = "DNS"
#   tags = {
#     Env = "${var.env}-${var.product}"
#   }
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "business_dev_cert" {
#   zone_id = aws_route53_zone.dev.zone_id
#   name    = tolist(aws_acm_certificate.business_dev.domain_validation_options)[0].resource_record_name
#   type    = tolist(aws_acm_certificate.business_dev.domain_validation_options)[0].resource_record_type
#   records = [tolist(aws_acm_certificate.business_dev.domain_validation_options)[0].resource_record_value]
#   ttl     = 60
#   lifecycle {
#     prevent_destroy = true
#   }
# }
# resource "aws_acm_certificate_validation" "business_dev" {
#   certificate_arn         = aws_acm_certificate.business_dev.arn
#   validation_record_fqdns = [aws_route53_record.business_dev_cert.fqdn]
# }

# resource "aws_route53_record" "prod_cert_us" {
#   provider = aws.vir
#   zone_id  = aws_route53_zone.prod.zone_id
#   name    = tolist(aws_acm_certificate.prod.domain_validation_options)[0].resource_record_name
#   type    = tolist(aws_acm_certificate.prod.domain_validation_options)[0].resource_record_type
#   records = [tolist(aws_acm_certificate.prod.domain_validation_options)[0].resource_record_value]
#   ttl      = 60
#   lifecycle {
#     ignore_changes = [records]
#   }
# }

# resource "aws_route53_record" "dev_cert_us" {
#   provider = aws.vir
#   zone_id  = aws_route53_zone.dev.zone_id
#   name    = tolist(aws_acm_certificate.dev.domain_validation_options)[0].resource_record_name
#   type    = tolist(aws_acm_certificate.dev.domain_validation_options)[0].resource_record_type
#   records = [tolist(aws_acm_certificate.dev.domain_validation_options)[0].resource_record_value]
#   ttl      = 60
#     lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "aws_acm_certificate_validation" "prod_us" {
#   provider               = aws.vir
#   certificate_arn        = aws_acm_certificate.prod_us.arn
#   validation_record_fqdns = [aws_route53_record.prod_cert_us.fqdn]
# }

# resource "aws_acm_certificate_validation" "dev_us" {
#   provider               = aws.vir
#   certificate_arn        = aws_acm_certificate.dev_us.arn
#   validation_record_fqdns = [aws_route53_record.dev_cert_us.fqdn]
# }
