resource "aws_route53_zone" "prod" {
  name = "fead.app"

  tags = {
    Env = "${var.env}-${var.prodect}"
  }
}

resource "aws_route53_zone" "dev" {
  name = "${var.env}.fead.app"

  tags = {
    Env = "${var.env}-${var.prodect}"
  }
}

resource "aws_route53_record" "dev-ns" {
  zone_id = aws_route53_zone.prod.zone_id
  name    = aws_route53_zone.dev.name
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.dev.name_servers
}

# certs for prod and dev in me-east-1

resource "aws_acm_certificate" "prod" {
  domain_name = "fead.app"
  validation_method = "DNS"

  tags = {
    Env = "${var.env}-${var.prodect}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "dev" {
  domain_name = "${var.env}.fead.app"
  validation_method = "DNS"

  tags = {
    Env = "${var.env}-${var.prodect}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "prod-cert" {
  zone_id = aws_route53_zone.prod.zone_id
  name    = aws_acm_certificate.prod.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.mprodain.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.prod.domain_validation_options.0.resource_record_value]
  ttl     = "60"
}

resource "aws_route53_record" "dev-cert" {
  zone_id = aws_route53_zone.dev.zone_id
  name    = aws_acm_certificate.dev.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.dev.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.dev.domain_validation_options.0.resource_record_value]
  ttl     = "60"
}

resource "aws_acm_certificate_validation" "prod" {
  certificate_arn         = aws_acm_certificate.prod.arn
  validation_record_fqdns = [aws_route53_record.prod-cert.fqdn]
}

resource "aws_acm_certificate_validation" "dev" {
  certificate_arn         = aws_acm_certificate.dev.arn
  validation_record_fqdns = [aws_route53_record.dev-cert.fqdn]
}


# certs for prod and dev in us-east-1

resource "aws_acm_certificate" "prod-us" {
  provider          = aws.vir
  domain_name = "fead.app"
  validation_method = "DNS"

  tags = {
    Env = "${var.env}-${var.prodect}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "dev-us" {
  provider          = aws.vir
  domain_name = "${var.env}.fead.app"
  validation_method = "DNS"

  tags = {
    Env = "${var.env}-${var.prodect}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "prod-cert-us" {
  provider          = aws.vir
  zone_id = aws_route53_zone.prod.zone_id
  name    = aws_acm_certificate.prod-us.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.prod-us.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.prod-us.domain_validation_options.0.resource_record_value]
  ttl     = "60"
}

resource "aws_route53_record" "dev-cert-us" {
  provider          = aws.vir
  zone_id = aws_route53_zone.dev.zone_id
  name    = aws_acm_certificate.dev-us.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.dev-us.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.dev-us.domain_validation_options.0.resource_record_value]
  ttl     = "60"
}

resource "aws_acm_certificate_validation" "prod-us" {
  provider          = aws.vir
  certificate_arn         = aws_acm_certificate.prod-us.arn
  validation_record_fqdns = [aws_route53_record.prod-cert-us.fqdn]
}

resource "aws_acm_certificate_validation" "dev-us" {
  provider          = aws.vir
  certificate_arn         = aws_acm_certificate.dev-us.arn
  validation_record_fqdns = [aws_route53_record.dev-cert-us.fqdn]
}


