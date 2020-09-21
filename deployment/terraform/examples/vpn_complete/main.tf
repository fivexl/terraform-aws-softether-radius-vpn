provider "aws" {
  region = "us-east-1"
}

data "aws_kms_key" "aws_ebs" {
  key_id = "alias/aws/ebs"
}

module "srvpn" {
  source                  = "../../"
  name                    = "softether-radius-vpn"
  create_logs             = true
  log_retention_days      = "1"
  create_dns              = true
  dns_zone_name           = "cageyv.com"
  dns_a_record            = "vpn"
  create_private_dns_zone = true
  private_dns_zone_name   = "internal"
  ami_name_prefix         = "softether-radius-vpn"
  ami_owner               = "self"
  vpc_id                  = "vpc-fb648686"
  public_subnet_tags      = { "Name" : "*-public-*" }
  instance_type           = "t2.micro"
  spot_price              = "0.0035"
  key_pair_name           = ""
  ebs_encrypt             = true
  root_block_kms_key_arn  = data.aws_kms_key.aws_ebs.arn
  target_cidr             = "172.31.0.0/16"
  vpn_cidr                = "172.16.0.0/24"
  vpn_admin_port          = "5555"
  ldap_addr               = "ldaps://ldap.jumpcloud.com:636"
  ldap_user_dn            = "uid={{username}},ou=users,o=XXXXXXXXXXXXXX,dc=jumpcloud,dc=com"
  duo_enabled             = false
  duo_ikey                = ""
  duo_skey                = ""
  duo_api_host            = ""
  tags = {
    "Project" : "softether-radius-vpn",
    "Terraform" : "true"
  }
}

output "this_vpn_dns_fqdn" {
  value = module.srvpn.this_vpn_dns_fqdn
}

output "this_vpn_private_dns_zone_name" {
  value = module.srvpn.this_vpn_private_dns_zone_name
}

output "this_vpn_public_ip" {
  value = module.srvpn.this_vpn_public_ip
}

output "this_vpn_ipsec_psk" {
  value     = module.srvpn.this_vpn_ipsec_psk
  sensitive = true
}

output "this_vpn_server_password" {
  value     = module.srvpn.this_vpn_server_password
  sensitive = true
}

output "this_vpn_push_route" {
  value = module.srvpn.this_vpn_push_route
}