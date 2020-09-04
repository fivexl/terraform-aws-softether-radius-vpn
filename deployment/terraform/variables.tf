#################
# VPN server
#################

variable "name" {
  description = "The name used for logs group, security groups, iam roles and VPN instance"
  type        = string
  default     = "softether-radius-vpn"
}

variable "tags" {
  description = "A mapping of tags"
  type        = map(string)
  default     = {}
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
  default     = true
}

variable "dns_zone_name" {
  description = "Name of Public DNS zone where record will be"
  type        = string
}

variable "dns_a_record" {
  description = "Name of A record in DNS zone"
  type        = string
  default     = "vpn"
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

variable "public_subnet_tags" {
  description = "Tags for search your public subnet"
  type        = map(string)
  default     = { "Type" : "Public" }
}

variable "instance_type" {
  description = "Type of EC2 instance. We recommend to use t3a.micro"
  type        = string
  default     = "t3a.micro"
}

variable "spot_price" {
  description = "Spot instance price. No used"
  type        = string
  default     = "0.0035"
}

variable "key_pair_name" {
  description = "Key pair name for SSH login to VPC instance"
  type        = string
  default     = ""
}

variable "ebs_encrypt" {
  description = "Do you need encrypt EBS storage for for VPC instance"
  type        = bool
  default     = true
}

variable "root_block_kms_key_arn" {
  description = "ARN of the KMS Key to use when encrypting the volume"
  type        = string
}

#################
# VPN variables
#################

variable "target_cidr" {
  description = "Typical your VPCs CIDR or any another CIDR used for target route"
  type        = string
}

variable "vpn_cidr" {
  description = "VPN CIDR. .1 - GW, .10-.200 Users IPs"
  type        = string
  default     = "172.16.0.0/24"
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