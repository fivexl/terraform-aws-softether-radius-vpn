variable "aws_dns_region" {}
variable "aws_dns_role_arn" {}
variable "aws_dns_external_id" {}
variable "aws_dns_session_name" {}

provider "aws" {
  alias  = "dns"
  region = var.aws_dns_region
  assume_role {
    role_arn     = var.aws_dns_role_arn
    external_id  = var.aws_dns_external_id
    session_name = var.aws_dns_session_name
  }
}

data "aws_route53_zone" "external_dns" {
  provider     = aws.dns
  name         = "fivexl.cloud"
  private_zone = false
}

resource "aws_route53_record" "external_dns" {
  provider = aws.dns
  count    = length(module.srvpn.this_vpn_dns_names_list)
  zone_id  = data.aws_route53_zone.external_dns.zone_id
  name     = format("%s.${data.aws_route53_zone.external_dns.name}", element(module.srvpn.this_vpn_dns_names_list, count.index))
  type     = "A"
  ttl      = "300"
  records  = [element(module.srvpn.this_vpn_public_ip_list, count.index)]
}

output "srvpn_vpn_external_dns_fqdn_list" {
  value = aws_route53_record.external_dns.*.fqdn
}
