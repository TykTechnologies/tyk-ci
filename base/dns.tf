# DNS and wildcard certificate for *.dev.tyk.technology

provider "cloudflare" {
  api_token = data.sops_file.secrets.data["cf-apitoken"]
  # account_id = "35b8134b47c7d01ee8198bb2b82a8dc5"
}

resource "cloudflare_record" "dev_tyk_tech" {
  for_each   = toset(aws_route53_zone.dev_tyk_tech.name_servers)
  depends_on = [aws_route53_zone.dev_tyk_tech]

  # This is the tyk.technology zone
  zone_id = "f3ee9e1c1e0e47f8ab60fae66d39aa8f"
  name    = "dev"
  type    = "NS"
  value   = each.value
}

resource "aws_route53_zone" "dev_tyk_tech" {
  name = "dev.tyk.technology"
}

resource "aws_ssm_parameter" "cd_zone" {
  name        = "/cd/zone"
  type        = "String"
  description = "Route53 zone ID for CD tasks"
  value       = aws_route53_zone.dev_tyk_tech.id
}

# One wildcard cert

resource "aws_acm_certificate" "dev_tyk_tech" {
  domain_name       = "*.dev.tyk.technology"
  validation_method = "DNS"
}

resource "aws_route53_record" "dev_tyk_tech" {
  for_each = {
    for dvo in aws_acm_certificate.dev_tyk_tech.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.dev_tyk_tech.zone_id
}

resource "aws_acm_certificate_validation" "dev_tyk_tech" {
  certificate_arn         = aws_acm_certificate.dev_tyk_tech.arn
  validation_record_fqdns = [for record in aws_route53_record.dev_tyk_tech : record.fqdn]
}
