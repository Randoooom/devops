resource "oci_email_email_domain" "this" {
  for_each = var.senders

  compartment_id = var.compartment_ocid
  name           = each.key

  freeform_tags = var.labels
}

resource "cloudflare_dns_record" "spf" {
  for_each = var.senders

  zone_id = data.cloudflare_zone.this.zone_id
  type    = "TXT"
  content = "v=spf1 include:eu.rp.oracleemaildelivery.com ~all"
  name    = each.key
  proxied = false
  ttl     = 1

  comment = "managed by terraform"
}

resource "oci_email_dkim" "this" {
  for_each = var.senders

  email_domain_id = oci_email_email_domain.this[each.key].id

  freeform_tags = var.labels
}

resource "cloudflare_dns_record" "dkim" {
  for_each = var.senders

  zone_id = data.cloudflare_zone.this.zone_id
  type    = "CNAME"
  content = oci_email_dkim.this[each.key].cname_record_value
  name    = oci_email_dkim.this[each.key].dns_subdomain_name
  proxied = false
  ttl     = 1

  comment = "managed by terraform"
}
