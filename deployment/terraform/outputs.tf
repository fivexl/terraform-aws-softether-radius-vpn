output "vpn_dns" {
  value = aws_route53_record.www.fqdn
}

output "vpn_ipsec_psk" {
  value = random_string.psk.result
}

output "vpn_server_password" {
  value = random_string.server_password.result
}
