provider "aws" {
  region = "eu-central-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  project_name       = lower("vpn")
  vpc_cidr           = "10.68.0.0/16" # 10.68.0.1 - 10.68.255.254
  vpc_azs_max        = 3
  vpc_azs_list       = slice(data.aws_availability_zones.available.names, 0, tonumber(local.vpc_azs_max))
  vpc_public_subnets = ["10.68.32.0/19", "10.68.64.0/19", "10.68.96.0/19"]
}

module "tag-generator" {
  source            = "fivexl/tag-generator/aws"
  version           = "1.0.1"
  prefix            = local.project_name
  terraform_managed = "1"
  terraform_state   = "./terraform.tfstate"
}

module "vpc" {
  source                         = "terraform-aws-modules/vpc/aws"
  version                        = "2.70.0"
  name                           = local.project_name
  cidr                           = local.vpc_cidr
  azs                            = local.vpc_azs_list
  public_subnets                 = local.vpc_public_subnets
  manage_default_security_group  = true
  default_security_group_name    = "default-${local.project_name}"
  default_security_group_ingress = []
  default_security_group_egress  = []
  tags                           = module.tag-generator.result
  enable_dns_hostnames           = true
  enable_dns_support             = true
}

module "srvpn" {
  source                           = "../../"
  name                             = "softether-radius-vpn"
  ami_name_prefix                  = "softether-radius-vpn"
  ami_owner                        = "self"
  azs                              = [module.vpc.azs[0]]
  subnets                          = [module.vpc.public_subnets[0]]
  vpc_id                           = module.vpc.vpc_id
  target_cidr                      = module.vpc.vpc_cidr_block
  ldap_addr                        = "ldaps://ldap.jumpcloud.com:636"
  ldap_user_dn                     = "uid={{username}},ou=users,o=XXXXXXXXXXXXXX,dc=jumpcloud,dc=com"
  tags                             = module.tag-generator.result
  tags_asg                         = module.tag-generator.result_asg_list
  create_logs                      = true
  log_retention_days               = 7
  create_dns                       = true
  dns_zone_name                    = "fivexl.cloud"
  dns_a_record_prefix              = "srvpn-"
  enable_azs_in_dns_a_record       = true
  create_private_dns_zone          = true
  private_domain_fqdn              = "internal.fivexl.cloud"
  instance_type                    = "t2.micro"
  enable_detailed_monitoring       = false
  enable_spot_instance             = true
  enable_session_manager_connect   = true
  vpn_cidr                         = "10.78.0.0/24" # 10.78.0.1 - 10.78.0.254
  vpn_dhcp_start                   = 10
  vpn_dhcp_end                     = 200
  vpn_admin_port                   = "5555"
  enable_vpn_admin_external_access = false
  enable_dhcp_gw                   = true
}

output "srvpn_vpn_dns_fqdn_list" {
  description = "DNS FQDN names of created VPN instance"
  value       = module.srvpn.this_vpn_dns_fqdn_list
}

output "srvpn_vpn_public_ip_list" {
  description = "The Public IPs of created VPN instance"
  value       = module.srvpn.this_vpn_public_ip_list
}

output "srvpn_vpn_ipsec_psk" {
  description = "Pre-shared Key for VPN clients"
  value       = module.srvpn.this_vpn_ipsec_psk
}

output "srvpn_vpn_server_password" {
  description = "VPN server admin password"
  value       = module.srvpn.this_vpn_server_password
}

output "srvpn_vpn_push_route" {
  description = "Route for VPN clients if they can't get DHCP Classless Static Routes"
  value       = module.srvpn.this_vpn_push_route
}

output "srvpn_security_group_id" {
  description = "VPN Security Group ID"
  value       = module.srvpn.this_security_group_id
}