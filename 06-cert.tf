# The entire section create a certificate, public zone, and validate the certificate using DNS method

# Create the certificate using a wildcard for all the domains created in chisom.ejim.click
resource "aws_acm_certificate" "chisomejim" {
  domain_name       = "*.chisomejim.click"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# get details about a hosted zone
data "aws_route53_zone" "chisomejim" {
  name         = "chisomejim.click"
  private_zone = false
}

# create a record set in route 53 for domain validation
resource "aws_route53_record" "chisomejim" {
  for_each = {
    for dvo in aws_acm_certificate.chisomejim.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.chisomejim.zone_id
}

# validate the certificate through DNS method
resource "aws_acm_certificate_validation" "chisomejim" {
  certificate_arn         = aws_acm_certificate.chisomejim.arn
  validation_record_fqdns = [for record in aws_route53_record.chisomejim : record.fqdn]
}

# create records for tooling
resource "aws_route53_record" "tooling" {
  zone_id = data.aws_route53_zone.chisomejim.zone_id
  name    = "tooling.chisomejim.click"
  type    = "A"

  alias {
    name                   = aws_lb.ext-alb.dns_name
    zone_id                = aws_lb.ext-alb.zone_id
    evaluate_target_health = true
  }
}

# create records for wordpress
resource "aws_route53_record" "wordpress" {
  zone_id = data.aws_route53_zone.chisomejim.zone_id
  name    = "wordpress.chisomejim.click"
  type    = "A"

  alias {
    name                   = aws_lb.ext-alb.dns_name
    zone_id                = aws_lb.ext-alb.zone_id
    evaluate_target_health = true
  }
}
