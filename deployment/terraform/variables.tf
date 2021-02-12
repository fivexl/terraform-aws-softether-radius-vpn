#################
# VPN server
#################

variable "name" {
  description = "The name used for logs group, security groups, iam roles, dns zone and VPN instance"
  type        = string
  default     = "softether-radius-vpn"
}

variable "tags" {
  description = "A mapping of tags"
  type        = map(string)
  default     = {}
}

variable "asg_tags" {
  description = "A list of ASG tags"
  default     = []
}

variable "create_logs" {
  description = "Create a group log in CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "How many days need to store logs"
  type        = number
  default     = 90
}

variable "create_dns" {
  description = "Create a dns record in Route53"
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "Name of Public DNS zone where record will be"
  type        = string
  default     = ""
}

variable "dns_a_record_prefix" {
  description = "Prefix for A record in DNS zone"
  type        = string
  default     = "vpn-"
}

variable "private_domain_fqdn" {
  description = "Domain FQDN which will be used to resolve internal names. (e.g.: internal.example.com)"
  type        = string
  default     = ""
}

variable "create_private_dns_zone" {
  description = "Create private DNS zone with private_domain_fqnd name and attach to VPC"
  type        = bool
  default     = false
}

#################
# Instance variables
#################

variable "ami_name_prefix" {
  description = "The name prefix used for search AMI image"
  type        = string
  default     = "softether-radius-vpn"
}

variable "ami_owner" {
  description = "The AMI owner"
  type        = string
  default     = "self"
}

variable "vpc_id" {
  description = "ID of the VPC where to create VPN instance"
  type        = string
}

variable "subnets" {
  description = "Subnets for VPN servers"
  type        = list(string)
}

variable "azs" {
  description = "List of AZs where subnets places"
  type        = list(string)
}

variable "instance_type" {
  description = "Type of EC2 instance. We recommend to use t3a.micro"
  type        = string
  default     = "t3a.micro"
}

variable "custom_ec2_spot_price" {
  description = "Custom EC2 Spot price"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "Key pair name for SSH login to VPC instance"
  type        = string
  default     = ""
}

variable "enable_detailed_monitoring" {
  description = "If `true`, the launched EC2 instance will have detailed monitoring enabled."
  type        = bool
  default     = false
}

variable "enable_spot_instance" {
  description = "Use spot instance for all VPN instances"
  type        = bool
  default     = true
}

variable "enable_session_manager_connect" {
  description = "Use Session Manager to connect to EC2 instance"
  type        = bool
  default     = true
}

#################
# VPN variables
#################

variable "target_cidr" {
  description = "Typical your VPCs CIDR or any another CIDR used for target route"
  type        = string
}

variable "vpn_cidr" {
  description = "VPN CIDR. .1 - GW"
  type        = string
  default     = "172.16.0.0/24"
}

variable "vpn_dhcp_start" {
  description = "VPN DHCP start cidrhost() hostnum"
  type        = number
  default     = 10
}

variable "vpn_dhcp_end" {
  description = "VPN DHCP end cidrhost() hostnum"
  type        = number
  default     = 200
}

variable "vpn_admin_port" {
  description = "VPN admin port for connect via MGMT client"
  type        = string
  default     = "5555"
}

#################
# Auth variables
#################

variable "ldap_addr" {
  description = "Your LDAP Address"
  type        = string
}

variable "ldap_user_dn" {
  description = "Your LDAP user DN"
  type        = string
}

variable "duo_enabled" {
  description = "Enable 2FA Duo"
  type        = bool
  default     = false
}

variable "duo_ikey" {
  description = "DUO ikey"
  type        = string
  default     = ""
}

variable "duo_skey" {
  description = "DUO skey"
  type        = string
  default     = ""
}

variable "duo_api_host" {
  description = "DUO API host"
  type        = string
  default     = ""
}