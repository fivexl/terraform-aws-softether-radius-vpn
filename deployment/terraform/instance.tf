data "aws_caller_identity" "i" {}

data "aws_ami" "ami" {
  most_recent = true
  owners      = [data.aws_caller_identity.i.account_id]
  name_regex  = "softether-radius-vpn*"
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = var.vpc_id
  tags   = var.subnet_tags
}

resource "aws_security_group" "vpn_sg" {
  name   = "vpn_instance_sg"
  vpc_id = var.vpc_id
  tags   = var.tags

  ingress {
    from_port = 500
    to_port   = 500
    protocol  = "udp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 4500
    to_port   = 4500
    protocol  = "udp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "vpn" {
  algorithm = "RSA"
}

resource "aws_key_pair" "vpn" {
  key_name   = "softether-radius-vpn"
  public_key = tls_private_key.vpn.public_key_openssh
}

# Install updates and restart instance
resource "aws_instance" "vpn" {
  source_dest_check           = false
  ami                         = data.aws_ami.ami.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.vpn.key_name
  subnet_id                   = sort(data.aws_subnet_ids.public_subnets.ids)[0]
  vpc_security_group_ids      = [aws_security_group.vpn_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.vpn.name
  tags                        = merge(map("Name", "vpn"), var.tags)
  user_data                   = data.template_cloudinit_config.vpn_config.rendered
}

resource "random_string" "psk" {
  length = 64
}

resource "random_string" "radius_secret" {
  length = 64
}

resource "random_string" "server_password" {
  length = 64
}

data "template_file" "softether_config" {
  template = file("${path.module}/templates/softether.config.template")
  vars = {
    PSK             = random_string.psk.result
    RADIUS_SECRET   = random_string.radius_secret.result
    SERVER_PASSWORD = random_string.server_password.result
    PUSH_ROUTE      = var.push_route
  }
}

data "template_file" "config_gcfg" {
  template = file("${path.module}/templates/config.gcfg.template")
  vars = {
    RADIUS_SECRET = random_string.radius_secret.result
    LDAP_ADDR     = var.ldap_addr
    USER_DN       = var.ldap_user_dn
    DUO_ENABLED   = var.duo_enabled
    DUO_IKEY      = var.duo_ikey
    DUO_SKEY      = var.duo_skey
    DUO_API_HOST  = var.duo_api_host
  }
}

data "template_file" "iptables_rules" {
  template = file("${path.module}/templates/iptables.rules.template")
  vars = {
    TARGET_CIDR = var.target_cidr
  }
}

data "template_file" "awslogs_conf" {
  template = file("${path.module}/templates/awslogs.conf.template")
  vars = {
    RSERVER_LOG      = local.rserver_log
    VPN_SERVER_LOG   = local.vpn_server_log
    VPN_SECURITY_LOG = local.vpn_security_log
  }
}

# TODO: Enable gzip and base64 (only together)
data "template_cloudinit_config" "vpn_config" {
  gzip          = false
  base64_encode = false
  # Generate file from softether.config.template into softether.config
  /*
  [   46.515346] cloud-init[3430]: /var/lib/cloud/instance/scripts/part-001: line 10: syntax error near unexpected token `('
  [   46.525012] cloud-init[3430]: /var/lib/cloud/instance/scripts/part-001: line 10: `IPsecEnable /L2TP:yes /L2TPRAW:no /ETHERIP:no /PSK:"123(@nk[9[@(123" /DEFAULTHUB:default'
  [   46.537391] cloud-init[3430]: Sep 01 09:25:32 cloud-init[3430]: util.py[WARNING]: Failed running /var/lib/cloud/instance/scripts/part-001 [2]
  */
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash
    sudo mkdir -p /usr/local/vpnserver/ && sudo touch /usr/local/vpnserver/softether.config
    sudo echo "${data.template_file.softether_config.rendered}" > /usr/local/vpnserver/softether.config
    sudo /usr/local/vpnserver/vpncmd localhost:5555 /SERVER /IN:softether.config /OUT:config.log
    sudo systemctl restart vpnserver
    EOF
  }
  # Generate config.gcfg.template and put it to /usr/local/rserver
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash
    sudo touch /usr/local/rserver/config.gcfg
    sudo echo "${data.template_file.config_gcfg.rendered}" > /usr/local/rserver/config.gcfg
    sudo chmod 700 /usr/local/rserver/config.gcfg && sudo chown nobody:nobody /usr/local/rserver/config.gcfg
    sudo systemctl enable rserver.service
    sudo systemctl start rserver.service
    EOF
  }
  # Generate awslogs.conf.template and put it to /etc/awslogs/awslogs.conf
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash
    sudo mkdir -p /etc/awslogs/ && sudo touch /etc/awslogs/awslogs.conf
    sudo echo "${data.template_file.awslogs_conf.rendered}" > /etc/awslogs/awslogs.conf
    sudo systemctl enable awslogsd.service
    sudo systemctl start awslogsd.service
    EOF
  }
  # Render template iptables.rules.template into /etc/iptables.rules and
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash
    sudo touch /etc/iptables.rules
    sudo echo TEST---TEST
    sudo echo
    sudo echo ${data.template_file.iptables_rules.rendered}
    sudo echo TEST---TEST
    sudo echo "${data.template_file.iptables_rules.rendered}" > /etc/iptables.rules
    sudo /usr/bin/iptablesload
    EOF
  }
  # Apply system configuration
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #!/bin/bash
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
