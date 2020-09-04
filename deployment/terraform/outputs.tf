locals {
  this_vpn_public_ip = var.create_logs ? aws_instance.this_with_logs[0].public_ip : aws_instance.this_without_logs[0].public_ip
  this_vpn_dns_fqdn  = var.create_dns ? aws_route53_record.this[0].fqdn : ""
}

output "this_vpn_dns_fqdn" {
  description = "The FQDN of created VPN instance"
  value       = local.this_vpn_dns_fqdn
}

output "this_vpn_public_ip" {
  description = "The Public IP of created VPN instance"
  value       = local.this_vpn_public_ip
}

output "this_vpn_ipsec_psk" {
  description = "Pre-shared Key for VPN clients"
  value       = random_password.psk.result
}

output "this_vpn_server_password" {
  description = "VPN server admin password"
  value       = random_password.server_password.result
}

output "this_vpn_push_route" {
  description = "Route for VPN clients if they can't get DHCP Classless Static Routes"
  value       = join("/", [cidrhost(var.target_cidr, 0), cidrnetmask(var.target_cidr), cidrhost(var.vpn_cidr, 1)])
}