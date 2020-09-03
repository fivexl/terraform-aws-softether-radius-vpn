locals {
  rserver_log      = format("%s/rserver", var.project_name)
  vpn_server_log   = format("%s/vpnserver_server_log", var.project_name)
  vpn_security_log = format("%s/vpnserver_security_log", var.project_name)
}

resource "aws_cloudwatch_log_group" "rserver" {
  name              = local.rserver_log
  retention_in_days = var.cloudwatch_loggroup_retention
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "vpn_server_log" {
  name              = local.vpn_server_log
  retention_in_days = var.cloudwatch_loggroup_retention
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "vpn_security_log" {
  name              = local.vpn_security_log
  retention_in_days = var.cloudwatch_loggroup_retention
  tags              = var.tags
}