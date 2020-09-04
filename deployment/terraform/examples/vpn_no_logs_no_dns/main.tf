provider "aws" {
  region = "us-east-1"
}

data "aws_kms_key" "aws_ebs" {
  key_id = "aws/ebs"
}

module "srvpn" {
  count                  = 1
  source                 = "../../"
  name                   = "softether-radius-vpn"
  create_logs            = false
  create_dns             = false
  ami_name_prefix        = "softether-radius-vpn"
  ami_owner              = "self"
  vpc_id                 = "vpc-fb648686"
  public_subnet_tags     = { "Name" : "*-public-*" }
  instance_type          = "t2.micro"
  spot_price             = "0.0035"
  key_pair_name          = ""
  ebs_encrypt            = true
  root_block_kms_key_arn = data.aws_kms_key.aws_ebs.arn
  target_cidr            = "172.31.0.0/16"
  vpn_cidr               = "172.16.0.0/24"
  vpn_admin_port         = "5555"
  ldap_addr              = "ldaps://ldap.jumpcloud.com:636"
  ldap_user_dn           = "uid={{username}},ou=users,o=XXXXXXXXXXXXXX,dc=jumpcloud,dc=com"
  duo_enabled            = false
  duo_ikey               = ""
  duo_skey               = ""
  duo_api_host           = ""
  tags = {
    "Project" : "softether-radius-vpn",
    "Terraform" : "true"
  }
}

output "this_vpn_dns_fqdn" {
  value = module.srvpn[0].this_vpn_dns_fqdn
}

output "this_vpn_public_ip" {
  value = module.srvpn[0].this_vpn_public_ip
}

output "this_vpn_ipsec_psk" {
  value = module.srvpn[0].this_vpn_ipsec_psk
}

output "this_vpn_server_password" {
  value = module.srvpn[0].this_vpn_server_password
}

output "this_vpn_push_route" {
  value = module.srvpn[0].this_vpn_push_route
}