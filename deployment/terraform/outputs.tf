locals {
  this_vpn_dns_fqdn                      = var.create_dns ? aws_route53_record.this[0].fqdn : ""
  this_vpn_private_dns_zone_name         = var.create_private_dns_zone ? aws_route53_zone.private[0].name : ""
  this_vpn_private_dns_zone_id           = var.create_private_dns_zone ? aws_route53_zone.private[0].zone_id : ""
  this_vpn_private_dns_zone_name_servers = var.create_private_dns_zone ? aws_route53_zone.private[0].name_servers : []
}

output "this_vpn_dns_fqdn" {
  description = "The FQDN of created VPN instance"
  value       = local.this_vpn_dns_fqdn
}

output "this_vpn_public_ip" {
  description = "The Public IP of created VPN instance"
  value       = aws_instance.this.public_ip
}

output "this_vpn_ipsec_psk" {
  description = "Pre-shared Key for VPN clients"
  value       = random_password.psk.result
  sensitive   = true
}

output "this_vpn_server_password" {
  description = "VPN server admin password"
  value       = random_password.server_password.result
  sensitive   = true
}

output "this_vpn_push_route" {
  description = "Route for VPN clients if they can't get DHCP Classless Static Routes"
  value       = join("/", [cidrhost(var.target_cidr, 0), cidrnetmask(var.target_cidr), cidrhost(var.vpn_cidr, 1)])
}

output "this_vpn_private_dns_zone_name" {
  description = "Private DNS zone name which used as an internal domain"
  value       = local.this_vpn_private_dns_zone_name
}

output "this_vpn_private_dns_zone_id" {
  description = "Private DNS zone id which used as an internal domain"
  value       = local.this_vpn_private_dns_zone_id
}

output "this_vpn_private_dns_zone_name_servers" {
  description = "Private DNS zone name servers which used as an internal domain"
  value       = local.this_vpn_private_dns_zone_name_servers
}
