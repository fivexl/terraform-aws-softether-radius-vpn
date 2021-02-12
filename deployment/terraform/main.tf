data "aws_region" "current" {}

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
# IAM
##################################

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
  tags               = var.tags
}

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

resource "aws_iam_policy" "logs" {
  count  = var.create_logs ? 1 : 0
  name   = var.name
  policy = data.aws_iam_policy_document.logs[0].json
}

resource "aws_iam_role_policy_attachment" "logs" {
  count      = var.create_logs ? 1 : 0
  policy_arn = aws_iam_policy.logs[0].arn
  role       = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_session_manager_connect ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.this.name
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
  path_awscli_config    = "/etc/awslogs/awscli.conf"
}

resource "random_password" "psk" {
  length           = 60
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  special          = true
  override_special = "_@!"
}

resource "random_password" "radius_secret" {
  length           = 60
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  special          = true
  override_special = "_@!"
}

resource "random_password" "server_password" {
  length           = 60
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  special          = true
  override_special = "_@!"
}

data "template_file" "softether_config" {
  template = file("${path.module}/templates/softether.config.tpl.sh")
  vars = {
    PSK             = random_password.psk.result
    RADIUS_SECRET   = random_password.radius_secret.result
    SERVER_PASSWORD = random_password.server_password.result
    DHCP_START      = cidrhost(var.vpn_cidr, var.vpn_dhcp_start)
    DHCP_END        = cidrhost(var.vpn_cidr, var.vpn_dhcp_end)
    DHCP_MASK       = cidrnetmask(var.vpn_cidr)
    DHCP_GW         = cidrhost(var.vpn_cidr, 1)
    DHCP_DNS        = cidrhost(var.vpn_cidr, 1)
    DOMAIN          = var.private_domain_fqdn != "" ? var.private_domain_fqdn : "none"
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
  template = file("${path.module}/templates/awslogs.conf.tpl.sh")
  vars = {
    RSERVER_LOG      = local.rserver_log
    VPN_SERVER_LOG   = local.vpn_server_log
    VPN_SECURITY_LOG = local.vpn_security_log
    FILE_PATH        = var.create_logs ? local.path_awslogs_config : "/dev/null"
  }
}

data "template_file" "awscli_conf" {
  template = file("${path.module}/templates/awscli.conf.tpl.sh")
  vars = {
    REGION    = data.aws_region.current.name
    FILE_PATH = var.create_logs ? local.path_awscli_config : "/dev/null"
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
  # Generate awscli.conf.template and put it to /etc/awslogs/awscli.conf
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.awscli_conf.rendered
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
# VPN Instances
##################################

data "aws_ami" "this" {
  most_recent = true
  owners      = [var.ami_owner]
  filter {
    name   = "name"
    values = ["${var.ami_name_prefix}*"]
  }
}

resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}

resource "aws_security_group" "this" {
  name        = var.name
  description = "Allow ${var.name} IPSEC/L2TP"
  vpc_id      = var.vpc_id
  ingress {
    description = "Allow Ingreess 500 UDP for ${var.name}"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Ingreess 4500 UDP for ${var.name}"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow Egress for ${var.name}"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_network_interface" "this" {
  count             = length(var.subnets)
  security_groups   = [aws_security_group.this.id]
  subnet_id         = element(var.subnets, count.index)
  source_dest_check = false
  tags              = var.tags
}

resource "aws_eip" "this" {
  count             = length(var.subnets)
  vpc               = true
  network_interface = element(aws_network_interface.this.*.id, count.index)
  tags              = var.tags
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
  count   = var.create_dns ? length(var.subnets) : 0
  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = format("${var.dns_a_record_prefix}%s.${data.aws_route53_zone.this[0].name}", count.index)
  type    = "A"
  ttl     = "300"
  records = [element(aws_eip.this.*.public_ip, count.index)]
}

resource "aws_route53_zone" "private" {
  count         = var.create_private_dns_zone && var.private_domain_fqdn != "" ? 1 : 0
  name          = var.private_domain_fqdn
  comment       = "Private DNS zone for ${var.name}. Used as is private internal domain"
  force_destroy = false
  tags          = var.tags
  vpc {
    vpc_id = var.vpc_id
  }
}

##################################
# LT and ASG
##################################

resource "aws_launch_template" "this" {
  count                  = length(var.subnets)
  name_prefix            = format("vpn-%s-", element(var.azs, count.index))
  description            = format("vpn-%s-%s-${var.name}", element(var.azs, count.index), element(var.subnets, count.index))
  update_default_version = true
  image_id               = data.aws_ami.this.image_id
  instance_type          = var.instance_type
  user_data              = data.template_cloudinit_config.this.rendered
  key_name               = var.key_pair_name
  network_interfaces {
    network_interface_id = element(aws_network_interface.this.*.id, count.index)
  }
  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  monitoring {
    enabled = var.enable_detailed_monitoring
  }
  tag_specifications {
    resource_type = "instance"
    tags          = { "Name" : var.name }
  }
  tag_specifications {
    resource_type = "volume"
    tags          = { "Name" : var.name }
  }
  tags = var.tags
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "ec2_spot_price" {
  count                         = var.custom_ec2_spot_price == "" ? 1 : 0
  source                        = "fivexl/ec2-spot-price/aws"
  version                       = "1.0.3"
  instance_type                 = var.instance_type
  availability_zones_names_list = data.aws_availability_zones.available.names
}

resource "aws_autoscaling_group" "this" {
  count                     = length(var.subnets)
  name_prefix               = format("vpn-%s-", element(var.azs, count.index))
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  availability_zones        = [element(var.azs, count.index)]
  health_check_type         = "EC2"
  health_check_grace_period = 120
  default_cooldown          = 120
  enabled_metrics           = ["GroupInServiceInstances"]
  capacity_rebalance        = true
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = element(aws_launch_template.this.*.id, count.index)
        version            = element(aws_launch_template.this.*.latest_version, count.index)
      }
      override {
        instance_type = var.instance_type
      }
    }
    instances_distribution {
      on_demand_base_capacity                  = var.enable_spot_instance ? 0 : 1 # how many on-demand
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
      spot_max_price                           = var.custom_ec2_spot_price == "" ? module.ec2_spot_price[0].spot_price_over : var.custom_ec2_spot_price
    }
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      instance_warmup        = 300
      min_healthy_percentage = 90
    }
  }
  tags = var.asg_tags
}
