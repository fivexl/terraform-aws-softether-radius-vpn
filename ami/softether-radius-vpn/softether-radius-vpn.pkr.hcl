variable "ami_region" {
  type    = string
  default = "${env("AWS_DEFAULT_REGION")}"
}

variable "aws_access_key" {
  type    = string
  default = ""
}

variable "aws_profile" {
  type    = string
  default = "${env("AWS_PROFILE")}"
}

variable "aws_secret_key" {
  type    = string
  default = ""
}

variable "name" {
  type    = string
  default = "softether-radius-vpn"
}

variable "rserver_version" {
  type    = string
  default = "v0.0.2"
}

variable "softether_vpnserver_version" {
  type    = string
  default = "4.34-9745-beta"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  ami_name = "${var.name}-amazon-linux-2-${local.timestamp}"
}

source "amazon-ebs" "amzn2" {
  access_key    = var.aws_access_key
  secret_key    = var.aws_secret_key
  ami_name      = local.ami_name
  instance_type = "t2.micro"
  encrypt_boot  = true
  profile       = var.aws_profile
  region        = var.ami_region
  run_tags = {
    Name = "builder for ${var.name}"
  }
  run_volume_tags = {
    Name = "builder for ${var.name}"
  }
  source_ami_filter {
    filters = {
      architecture        = "x86_64"
      name                = "amzn2-ami-hvm-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["137112412989"]
  }
  ssh_pty      = "true"
  ssh_username = "ec2-user"
  tags = {
    Name              = var.name
    rserver_ver       = var.rserver_version
    softether_vpn_ver = var.softether_vpnserver_version
  }
}

build {
  sources = ["source.amazon-ebs.amzn2"]
  provisioner "shell" {
    inline = ["while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done"]
  }
  provisioner "shell" {
    inline = ["sudo rm /root/.ssh/authorized_keys", "rm /home/ec2-user/.ssh/authorized_keys"]
  }
  provisioner "shell" {
    inline = ["mkdir /tmp/vpn"]
  }
  provisioner "file" {
    destination = "/tmp/vpn"
    source      = "scripts"
  }
  provisioner "shell" {
    inline = ["sudo yum -y update", "sudo yum -y upgrade", "sudo amazon-linux-extras install epel -y", "sudo yum clean all"]
  }
  provisioner "shell" {
    inline = [
      "curl -OL https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/archive/v${var.softether_vpnserver_version}.tar.gz",
      "tar xvf v${var.softether_vpnserver_version}.tar.gz && rm -rf v${var.softether_vpnserver_version}.tar.gz",
      "cd SoftEtherVPN_Stable-${var.softether_vpnserver_version}", "echo Use development tools to build VPN",
      "sudo yum groupinstall \"Development Tools\" -y", "sudo yum install readline-devel ncurses-devel openssl-devel -y",
      "echo Set RADIUS_RETRY_TIMEOUT to 60. Currently hardcoded to 10",
      "sed -i 's|#define\\s\\{1,\\}RADIUS_RETRY_TIMEOUT\\s\\{1,\\}(10\\s\\{1,\\}\\*\\s\\{1,\\}1000)|#define RADIUS_RETRY_TIMEOUT (60 * 1000)|' src/Cedar/Radius.h",
      "grep RADIUS_RETRY_TIMEOUT src/Cedar/Radius.h",
      "./configure", "make", "sudo make install",
      "rm -rf ~/SoftEtherVPN_Stable-${var.softether_vpnserver_version}", "cd /usr/vpncmd/",
      "sudo chmod 600 .",
      "sudo chmod 700 vpncmd",
      "sudo yum groups remove \"Development Tools\" -y",
      "echo based on base on https://www.softether.org/4-docs/1-manual/7._Installing_SoftEther_VPN_Server/7.3_Install_on_Linux_and_Initial_Configurations#7.3.8_Registering_a_Startup_Script",
      "sudo mv /tmp/vpn/scripts/vpnserver /etc/init.d/vpnserver",
      "sudo chmod 755 /etc/init.d/vpnserver",
      "sudo /sbin/chkconfig --add vpnserver"
    ]
  }
  provisioner "shell" {
    inline = [
      "curl -OL https://releases.fivexl.io/golang-radius-server-ldap-with-mfa/${var.rserver_version}/rserver_${var.rserver_version}_linux_amd64.zip",
      "unzip rserver_${var.rserver_version}_linux_amd64.zip", "rm -rf rserver_${var.rserver_version}_linux_amd64.zip",
      "sudo mkdir /usr/local/rserver",
      "sudo mv ./rserver /usr/local/rserver/rserver",
      "sudo chmod -R 600 /usr/local/rserver/",
      "sudo chmod 700 /usr/local/rserver /usr/local/rserver/rserver",
      "sudo chown -R nobody:nobody /usr/local/rserver/",
      "sudo mv /tmp/vpn/scripts/rserver.service /lib/systemd/system/"
    ]
  }
  provisioner "shell" {
    inline = ["sudo yum install -y awslogs"]
  }
  provisioner "shell" {
    inline = ["sudo mv /tmp/vpn/scripts/iptablesload /usr/bin/", "sudo cp /tmp/vpn/scripts/sysctl.conf /etc/sysctl.conf"]
  }
  post-processor "manifest" {
    output     = "/tmp/manifest.json"
    strip_path = true
  }
}
