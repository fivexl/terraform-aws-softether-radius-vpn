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
