output "vpn_dns" {
  value = aws_route53_record.this.fqdn
}

output "vpn_public_ip" {
  value = aws_instance.this.public_ip
}

output "vpn_ipsec_psk" {
  value = random_password.psk.result
}

output "vpn_server_password" {
  value = random_password.server_password.result
}

output "vpn_push_route" {
  value = join("/", [cidrhost(var.target_cidr, 0), cidrnetmask(var.target_cidr), cidrhost(var.vpn_cidr, 1)])
}