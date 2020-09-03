data "aws_caller_identity" "this" {}

data "aws_ami" "this" {
  most_recent = true
  owners      = [data.aws_caller_identity.this.account_id]
  name_regex  = "${var.project_name}*"
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = var.vpc_id
  tags   = var.public_subnet_tags
}

resource "aws_security_group" "this" {
  name        = var.project_name
  description = "Allow ${var.project_name} IPSEC/L2TP"
  vpc_id      = var.vpc_id
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


# Install updates and restart instance
resource "aws_instance" "this" {
  ami                         = data.aws_ami.this.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.this.id]
  subnet_id                   = sort(data.aws_subnet_ids.public_subnets.ids)[0] #TODO: Random choose subnet
  associate_public_ip_address = true
  source_dest_check           = false
  user_data                   = data.template_cloudinit_config.this.rendered
  iam_instance_profile        = aws_iam_instance_profile.this.name
  tags                        = merge(map("Name", "ext-vpn"), var.tags)
  root_block_device {
    encrypted  = true
    kms_key_id = var.root_block_kms_key_arn
  }
}

resource "random_password" "psk" {
  length = 60
  min_lower = 1
  min_upper = 1
  min_numeric = 1
  special = true
  override_special = "_@%"
}

resource "random_password" "radius_secret" {
  length = 60
  min_lower = 1
  min_upper = 1
  min_numeric = 1
  special = true
  override_special = "_@%"
}

resource "random_password" "server_password" {
  length = 60
  min_lower = 1
  min_upper = 1
  min_numeric = 1
  special = true
  override_special = "_@%"
}

data "template_file" "softether_config" {
  template = file("${path.module}/templates/softether.config.tpl.sh")
  vars = {
    PSK             = random_password.psk.result
    RADIUS_SECRET   = random_password.radius_secret.result
    SERVER_PASSWORD = random_password.server_password.result
    DHCP_START      = cidrhost(var.vpn_cidr, 10)
    DHCP_END        = cidrhost(var.vpn_cidr, 200)
    DHCP_MASK       = cidrnetmask(var.vpn_cidr)
    DHCP_GW         = cidrhost(var.vpn_cidr, 1)
    DHCP_DNS        = cidrhost(var.vpn_cidr, 1)
    PUSH_ROUTE      = join("/", [cidrhost(var.target_cidr, 0), cidrnetmask(var.target_cidr), cidrhost(var.vpn_cidr, 1)])
    FILE_PATH       = var.path_softether_config
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
    FILE_PATH     = var.path_rserver_config
  }
}

data "template_file" "iptables_rules" {
  template = file("${path.module}/templates/iptables.rules.tpl.sh")
  vars = {
    VPN_CIDR    = var.vpn_cidr
    TARGET_CIDR = var.target_cidr
    FILE_PATH   = var.path_iptables_rules
  }
}

data "template_file" "awslogs_conf" {
  template = file("${path.module}/templates/awslogs.conf.tpl.sh")
  vars = {
    RSERVER_LOG      = local.rserver_log
    VPN_SERVER_LOG   = local.vpn_server_log
    VPN_SECURITY_LOG = local.vpn_security_log
    FILE_PATH        = var.path_awslogs_config
  }
}

data "template_cloudinit_config" "this" {
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
    content      = data.template_file.awslogs_conf.rendered
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
    sudo /usr/local/vpnserver/vpncmd localhost:"${var.vpn_admin_port}" /SERVER /IN:"${var.path_softether_config}" /OUT:config.log
    sudo chmod 700 "${var.path_rserver_config}" && sudo chown nobody:nobody "${var.path_rserver_config}"
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
