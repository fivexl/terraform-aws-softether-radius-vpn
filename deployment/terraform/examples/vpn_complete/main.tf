provider "aws" {
  region = "us-east-1"
}

data "aws_kms_key" "aws_ebs" {
  key_id = "alias/aws/ebs"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  project_name             = lower("vpn")
  vpn_cidr                 = "10.78.0.0/24" # 10.78.0.1 - 10.78.0.254
  vpc_cidr                 = "10.68.0.0/16" # 10.68.0.1 - 10.68.255.254
  vpc_azs_max              = 3
  vpc_public_subnets       = ["10.68.32.0/19", "10.68.64.0/19", "10.68.96.0/19"]
  vpc_private_subnets      = ["10.68.128.0/19", "10.68.160.0/19", "10.68.192.0/19"]
  vpc_database_subnets     = ["10.68.225.0/24", "10.68.226.0/24", "10.68.227.0/24"]
  vpc_elasticache_subnets  = ["10.68.228.0/24", "10.68.229.0/24", "10.68.230.0/24"]
  vpc_intra_subnets        = ["10.68.235.0/24", "10.68.236.0/24", "10.68.237.0/24"]
}

module "vpc" {
  source                                          = "terraform-aws-modules/vpc/aws"
  version                                         = "2.64.0"
  name                                            = local.project_name
  cidr                                            = local.vpc_cidr
  azs                                             = slice(data.aws_availability_zones.available.names, 0, tonumber(local.vpc_azs_max))
  public_subnets                                  = local.vpc_public_subnets
  private_subnets                                 = local.vpc_private_subnets
  database_subnets                                = local.vpc_database_subnets
  elasticache_subnets                             = local.vpc_elasticache_subnets
  intra_subnets                                   = local.vpc_intra_subnets
  enable_dns_hostnames                            = true
  enable_dns_support                              = true
  create_database_subnet_group                    = true
  enable_nat_gateway                              = true
  single_nat_gateway                              = true
  one_nat_gateway_per_az                          = true
  enable_vpn_gateway                              = false
  manage_default_security_group                   = true
  default_security_group_name                     = "default-${local.project_name}"
  default_security_group_ingress                  = []
  default_security_group_egress                   = []
  enable_s3_endpoint                              = false
  enable_public_s3_endpoint                       = false
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 60
  vpc_flow_log_tags = {
    Name = "vpc-flow-logs-cloudwatch-logs-${local.project_name}"
  }
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
  vpc_id                  = module.vpc.vpc_id
  public_subnet_tags      = { "Name" : "*-public-*" }
  instance_type           = "t2.micro"
  spot_price              = "0.0035"
  key_pair_name           = ""
  ebs_encrypt             = true
  root_block_kms_key_arn  = data.aws_kms_key.aws_ebs.arn
  target_cidr             = local.vpc_cidr
  vpn_cidr                = local.vpn_cidr
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
}

output "this_vpn_server_password" {
  value     = module.srvpn.this_vpn_server_password
}

output "this_vpn_push_route" {
  value = module.srvpn.this_vpn_push_route
}