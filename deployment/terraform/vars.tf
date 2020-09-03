# Global vars
variable "region" {
  type = string
}

variable "project_name" {
  type        = string
  description = "Name of project. Used for create names of SG, CW, ASG and etc."
  default     = "softether-radius-vpn"
}

variable "dns_zone_name" {
  type = string
}

variable "tags" {
  type = map
}

variable "cloudwatch_loggroup_retention" {
  default = 90
}

# Instance vars
variable "instance_type" {
  default = "t3.medium"
}

variable "spot_price" {
  default = "0.02"
}

variable "associate_public_ip_address" {
  type    = bool
  default = true
}

variable "key_pair_name" {
  type = string
}

variable "root_block_kms_key_arn" {
  description = "ARN of the KMS Key to use when encrypting the volume"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_tags" {
  type    = map
  default = { "Type" : "Public" }
}

# VPN vars
variable "target_cidr" {
  default = "10.0.0.0/8"
}

variable "vpn_cidr" {
  default = "172.17.0.0/24"
}

variable "vpn_admin_port" {
  default = "5555"
}

# LDAP vars
variable "ldap_addr" {
  type = string
}

variable "ldap_user_dn" {
  type = string
}

# Duo vars
variable "duo_enabled" {
  default = false
}

variable "duo_ikey" {
  default = ""
}

variable "duo_skey" {
  default = ""
}

variable "duo_api_host" {
  default = ""
}

# Advanced vars
variable "path_softether_config" {
  default = "/usr/local/vpnserver/softether.config"
}

variable "path_rserver_config" {
  default = "/usr/local/rserver/config.gcfg"
}

variable "path_iptables_rules" {
  default = "/etc/iptables.rules"
}

variable "path_awslogs_config" {
  default = "/etc/awslogs/awslogs.conf"
}