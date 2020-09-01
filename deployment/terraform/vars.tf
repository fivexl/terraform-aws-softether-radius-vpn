variable "vpc_id" {
  type = string
}

variable "subnet_tags" {
  type    = map
  default = { "Type" : "Public" }
}

variable "dns_zone_name" {
  type = string
}

variable "instance_type" {
  default = "t3.medium"
}

variable "spot_price" {
  default = "0.02"
}

variable "push_route" {
  default = "10.0.0.0/255.0.0.0/192.168.30.1"
}

variable "target_cidr" {
  default = "10.0.0.0/8"
}

variable "ldap_addr" {
  type = string
}

variable "ldap_user_dn" {
  type = string
}

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

variable "tags" {
  type = map
}

variable "cloudwatch_loggroup_name" {
  default = "softether-radius-vpn"
}

variable "cloudwatch_loggroup_retention" {
  default = 90
}