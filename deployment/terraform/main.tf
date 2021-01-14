##################################
# CloudWatch Logs
##################################

locals {
  rserver_log      = format("%s/rserver", var.name)
  vpn_server_log   = format("%s/vpnserver_server_log", var.name)
  vpn_security_log = format("%s/vpnserver_security_log", var.name)
}

resource "aws_cloudwatch_log_group" "rserver" {
  count             = var.create_logs ? 1 : 0
  name              = local.rserver_log
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "vpn_server_log" {
  count             = var.create_logs ? 1 : 0
  name              = local.vpn_server_log
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "vpn_security_log" {
  count             = var.create_logs ? 1 : 0
  name              = local.vpn_security_log
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

##################################
# VPC
##################################

data "aws_vpc" "this" {
  id = var.vpc_id
}


##################################
# Route53 Record
##################################

data "aws_route53_zone" "this" {
  count        = var.create_dns ? 1 : 0
  name         = var.dns_zone_name
  private_zone = false
}

resource "aws_route53_record" "this" {
  count   = var.create_dns ? 1 : 0
  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = "${var.dns_a_record}.${data.aws_route53_zone.this[0].name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.this.public_ip]
}

resource "aws_route53_zone" "private" {
  count         = var.create_dns && var.create_private_dns_zone ? 1 : 0
  name          = "${var.private_dns_zone_name}.${data.aws_route53_zone.this[0].name}"
  comment       = "Private DNS zone for ${var.name}. Used as is private internal domain"
  force_destroy = false
  tags          = merge(map("Name", var.name), var.tags)
  vpc {
    vpc_id = data.aws_vpc.this.id
  }
}

##################################
# IAM
##################################

data "aws_iam_policy_document" "logs" {
  count = var.create_logs ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      aws_cloudwatch_log_group.rserver[0].arn,
      aws_cloudwatch_log_group.vpn_server_log[0].arn,
      aws_cloudwatch_log_group.vpn_security_log[0].arn,
      "${aws_cloudwatch_log_group.rserver[0].arn}:log-stream:*",
      "${aws_cloudwatch_log_group.vpn_server_log[0].arn}:log-stream:*",
      "${aws_cloudwatch_log_group.vpn_security_log[0].arn}:log-stream:*"
    ]
  }
}

data "aws_iam_policy_document" "trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = var.name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy" "logs" {
  count  = var.create_logs ? 1 : 0
  name   = var.name
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.logs[0].json
}

resource "aws_iam_instance_profile" "this" {
  name = var.name
  role = aws_iam_role.this.name
}

##################################
# Configs and passwords
##################################

locals {
  path_softether_config = "/usr/local/vpnserver/softether.config"
  path_rserver_config   = "/usr/local/rserver/config.gcfg"
  path_iptables_rules   = "/etc/iptables.rules"
  path_awslogs_config   = "/etc/awslogs/awslogs.conf"
  private_domain        = var.create_dns && var.create_private_dns_zone ? aws_route53_zone.private[0].name : "none"
}

resource "random_password" "psk" {
  length           = 60
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  special          = true
  override_special = "_@%"
}

resource "random_password" "radius_secret" {
  length           = 60
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  special          = true
  override_special = "_@%"
}

resource "random_password" "server_password" {
  length           = 60
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  special          = true
  override_special = "_@%"
}

data "template_file" "softether_config" {
  template = file("${path.module}/templates/softether.config.tpl.sh")
  vars = {
    PSK             = random_password.psk.result
    RADIUS_SECRET   = random_password.radius_secret.result
    SERVER_PASSWORD = random_password.server_password.result
    DHCP_START      = cidrhost(var.vpn_cidr, 10)
    DHCP_END        = cidrhost(var.vpn_cidr, 200) #TODO: subnets bigger more than /24
    DHCP_MASK       = cidrnetmask(var.vpn_cidr)
    DHCP_GW         = cidrhost(var.vpn_cidr, 1)
    DHCP_DNS        = cidrhost(var.vpn_cidr, 1)
    DOMAIN          = local.private_domain
    PUSH_ROUTE      = join("/", [cidrhost(var.target_cidr, 0), cidrnetmask(var.target_cidr), cidrhost(var.vpn_cidr, 1)])
    FILE_PATH       = local.path_softether_config
  }
}

data "template_file" "config_gcfg" {
  template = file("${path.module}/templates/config.gcfg.tpl.sh")
  vars = {
    RADIUS_SECRET = random_password.radius_secret.result
    LDAP_ADDR     = var.ldap_addr
    USER_DN       = var.ldap_user_dn
    DUO_ENABLED   = var.duo_enabled
    DUO_IKEY      = var.duo_ikey
    DUO_SKEY      = var.duo_skey
    DUO_API_HOST  = var.duo_api_host
    FILE_PATH     = local.path_rserver_config
  }
}

data "template_file" "iptables_rules" {
  template = file("${path.module}/templates/iptables.rules.tpl.sh")
  vars = {
    VPN_CIDR    = var.vpn_cidr
    TARGET_CIDR = var.target_cidr
    FILE_PATH   = local.path_iptables_rules
  }
}

data "template_file" "awslogs_conf" {
  count    = var.create_logs ? 1 : 0
  template = file("${path.module}/templates/awslogs.conf.tpl.sh")
  vars = {
    RSERVER_LOG      = local.rserver_log
    VPN_SERVER_LOG   = local.vpn_server_log
    VPN_SECURITY_LOG = local.vpn_security_log
    FILE_PATH        = local.path_awslogs_config
  }
}

data "template_cloudinit_config" "this_with_logs" {
  count         = var.create_logs ? 1 : 0
  gzip          = true
  base64_encode = true
  # Generate softether_config.template and put it to /usr/local/vpnserver/softether.config
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.softether_config.rendered
  }
  # Generate config.gcfg.template and put it to /usr/local/rserver
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.config_gcfg.rendered
  }
  # Generate awslogs.conf.template and put it to /etc/awslogs/awslogs.conf
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.awslogs_conf[0].rendered
  }
  # Render template iptables.rules.template into /etc/iptables.rules and
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.iptables_rules.rendered
  }
  # Post config
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash
    sudo /usr/local/vpnserver/vpncmd localhost:"${var.vpn_admin_port}" /SERVER /IN:"${local.path_softether_config}" /OUT:config.log
    sudo chmod 700 "${local.path_rserver_config}" && sudo chown nobody:nobody "${local.path_rserver_config}"
    sudo systemctl restart vpnserver
    sudo systemctl enable rserver.service
    sudo systemctl start rserver.service
    sudo systemctl enable awslogsd.service
    sudo systemctl start awslogsd.service
    sudo /usr/bin/iptablesload
    sudo sysctl -p
    EOF
  }
  # Those are useful when VPN is not working for some reason
  # (you can check those logs if you go EC2 -> select instance -> Actions -> Instance Settings -> Get System Log)
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash
    sudo systemctl status rserver.service
    sudo systemctl status vpnserver
    sudo journalctl -eu rserver --no-pager --lines 25
    sudo journalctl -eu vpnserver --no-pager --lines 25
    EOF
  }
}

data "template_cloudinit_config" "this_without_logs" {
  count         = var.create_logs ? 0 : 1
  gzip          = true
  base64_encode = true
  # Generate softether_config.template and put it to /usr/local/vpnserver/softether.config
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.softether_config.rendered
  }
  # Generate config.gcfg.template and put it to /usr/local/rserver
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.config_gcfg.rendered
  }
  # Render template iptables.rules.template into /etc/iptables.rules and
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.iptables_rules.rendered
  }
  # Post config
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash
    sudo /usr/local/vpnserver/vpncmd localhost:"${var.vpn_admin_port}" /SERVER /IN:"${local.path_softether_config}" /OUT:config.log
    sudo chmod 700 "${local.path_rserver_config}" && sudo chown nobody:nobody "${local.path_rserver_config}"
    sudo systemctl restart vpnserver
    sudo systemctl enable rserver.service
    sudo systemctl start rserver.service
    sudo systemctl enable awslogsd.service
    sudo systemctl start awslogsd.service
    sudo /usr/bin/iptablesload
    sudo sysctl -p
    EOF
  }
  # Those are useful when VPN is not working for some reason
  # (you can check those logs if you go EC2 -> select instance -> Actions -> Instance Settings -> Get System Log)
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash
    sudo systemctl status rserver.service
    sudo systemctl status vpnserver
    sudo journalctl -eu rserver --no-pager --lines 25
    sudo journalctl -eu vpnserver --no-pager --lines 25
    EOF
  }
}

##################################
# Instance info
##################################

data "aws_ami" "this" {
  most_recent = true
  owners      = [var.ami_owner]
  name_regex  = "${var.ami_name_prefix}*"
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = data.aws_vpc.this.id
  tags   = var.public_subnet_tags
}

resource "random_shuffle" "subnet" {
  input        = data.aws_subnet_ids.public_subnets.ids #TODO: list of subnet ids
  result_count = 1
}

resource "aws_security_group" "this" {
  name        = var.name
  description = "Allow ${var.name} IPSEC/L2TP"
  vpc_id      = data.aws_vpc.this.id
  tags        = var.tags

  ingress {
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################################
# VPN Instance
##################################

locals {
  this_instance_user_data = var.create_logs ? data.template_cloudinit_config.this_with_logs[0].rendered : data.template_cloudinit_config.this_without_logs[0].rendered
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.this.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = random_shuffle.subnet.result[0]
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = local.this_instance_user_data
  iam_instance_profile        = aws_iam_instance_profile.this.name
  tags                        = merge(map("Name", var.name), var.tags)
  root_block_device {
    encrypted  = var.ebs_encrypt
    kms_key_id = var.root_block_kms_key_arn
  }
}