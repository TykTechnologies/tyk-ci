provider "cloudflare" {
  version = "~> 2.0"
  account_id = "35b8134b47c7d01ee8198bb2b82a8dc5"
}

resource "cloudflare_record" "dev_tyk_tech" {
  for_each = toset(aws_route53_zone.dev_tyk_tech.name_servers)
  
  # This is the tyk.technology zone
  zone_id = "f3ee9e1c1e0e47f8ab60fae66d39aa8f"
  name    = "dev"
  type    = "NS"
  value = each.value
}
