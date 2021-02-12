locals {
  this_vpn_dns_fqdn_list  = var.create_dns ? aws_route53_record.this.*.fqdn : [""]
  this_vpn_dns_names_list = var.enable_azs_in_dns_a_record ? [for az in var.azs : format("${var.dns_a_record_prefix}%s", az)] : [for number in length(var.azs) : format("${var.dns_a_record_prefix}%s", number)]
}

output "this_vpn_dns_fqdn_list" {
  description = "List of FQDN for created VPN instances"
  value       = local.this_vpn_dns_fqdn_list
}

output "this_vpn_dns_names_list" {
  description = "List of DNS names for created VPN instances. Useful if DNS zone in separate account."
  value       = local.this_vpn_dns_names_list
}

output "this_vpn_public_ip_list" {
  description = "The Public IPs of created VPN instance"
  value       = aws_eip.this.*.public_ip
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

output "this_security_group_id" {
  description = "Security Group ID attached to VPN"
  value = aws_security_group.this.id
}