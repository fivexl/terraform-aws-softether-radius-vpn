[![FivexL](https://releases.fivexl.io/fivexlbannergit.jpg)](https://fivexl.io/)

# AWS Client SRVPN Terraform module

Softether based VPN with LDAP/MFA auth via RADIUS with multi-AZ deployment

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | >= 3.13.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name used for logs group, security groups, iam roles, dns zone and VPN instance. | `string` | `softether-radius-vpn` | no |
| vpc_id | ID of the VPC where to create VPN instance | `string` |  | yes |
| subnets | Subnets for VPN servers | `list(string)` |  | yes |
| azs | List of AZs where subnets places | `list(string)` |  | yes |
| target_cidr | Typical your VPCs CIDR or any another CIDR used for target route | `string` | | yes |
| ldap_addr | Your LDAP Address (e.g. ldaps://ldap.jumpcloud.com:636) | `string` | | yes |
| ldap_user_dn | Your LDAP user DN (e.g.: uid={{username}},ou=users,o=****,dc=jumpcloud,dc=com) | `string` | | yes |
| duo_enabled | Enable 2FA Duo | `bool` | `false` | no |
| duo_ikey | DUO ikey | `string` | `""` | no |
| duo_skey | DUO skey | `string` | `""` | no |
| duo_api_host | DUO API host | `string` | `""` | no |
| instance_type | Type of EC2 instance. We recommend to use t3a.micro | `string` | `"t3a.micro"` | no |
| enable_spot_instance | Use spot instance for all VPN instances | `bool` | `true` | no |
| ami_name_prefix | The name prefix used for search AMI image | `string` | `"softether-radius-vpn"` | no |
| ami_owner | The AMI owner | `string` | `"self"` | no |
| tags | A mapping of tags. | `map(string)` | `{}` | no |
| tags_asg | A list of ASG tags | `list()` | `[]` | no |
| create_logs | Create a group log in CloudWatch | `bool` | `true` | no |
| log_retention_days | How many days need to store logs | `number` | `90` | no |
| create_dns | Create a dns record in Route53 | `bool` | `false` | no |
| dns_zone_name | Name of Public DNS zone where record will be. DNS zone must exist. | `string` | `""` | no |
| dns_a_record_prefix | Prefix for A record in DNS zone | `string` | `"vpn-"` | no | 
| enable_azs_in_dns_a_record | Enable AZs in dns A record for VPN or use numbers (from 0). | `bool` | `false` | no |
| private_domain_fqdn | Domain FQDN which will be used to resolve internal names. (e.g.: internal.example.com) | `string` | `""` | no |
| create_private_dns_zone | Create private DNS zone with private_domain_fqnd name and attach to VPC | `bool` | `false` | no |
| custom_ec2_spot_price | Custom EC2 Spot price | `string` | `""` | no |
| key_pair_name | Key pair name for SSH login to VPC instance | `string` | `""` | no |
| enable_detailed_monitoring | If `true`, the launched EC2 instance will have detailed monitoring enabled. | `bool` | `false` | no |
| enable_session_manager_connect | Use Session Manager to connect to EC2 instance | `bool` | `true` | no |
| vpn_cidr | VPN CIDR. .1 - GW | `string` | `"172.16.0.0/24"` | no |
| vpn_dhcp_start | VPN DHCP start cidrhost() hostnum | `number` | `10` | no |
| vpn_dhcp_end | VPN DHCP end cidrhost() hostnum | `number` | `200` | no |
| vpn_admin_port | VPN admin port for connect via MGMT client | `string` | `"5555"` | no |
| enable_dhcp_gw | Enable push Gateway to clients. Route all networks through VPN. | `bool` | `true` | no |
| enable_vpn_admin_external_access | Enable external access to admin MGMT. It used only for maintenance. Only external IP of the operator. | `bool` | `false` | no |


## Outputs

| Name | Description |
|------|-------------|
| this_vpn_dns_fqdn_list | List of FQDN for created VPN instances |
| this_vpn_dns_names_list | List of DNS names for created VPN instances. Useful if DNS zone in separate account. |
| this_vpn_public_ip_list | The Public IPs of created VPN instance |
| this_vpn_ipsec_psk | Pre-shared Key for VPN clients |
| this_vpn_server_password | VPN server admin password |
| this_vpn_push_route | Route for VPN clients if they can't get DHCP Classless Static Routes |
| this_security_group_id | Security Group ID attached to VPN  |

## License

Apache 2 Licensed. See LICENSE for full details.

## How build own AMI for SRVPN
- Prepare AWS credentials. Environment variables AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY or AWS_PROFILE are supported.
- [Install Hashicorp Packer](https://learn.hashicorp.com/tutorials/packer/getting-started-install?in=packer/getting-started)
- [Build an Image](https://learn.hashicorp.com/tutorials/packer/getting-started-build-image?in=packer/getting-started): run `packer build softether-radius-vpn.json` in `ami/softether-radius-vpn` folder

### Packer variables
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Used for AMI prefix and tags. | `string` | `softether-radius-vpn` | no |
| ami_region | AWS region where AMI will be builds and stored  | `string` | `env AWS_DEFAULT_REGION` | yes |
| rserver_version | Version of [RServer](https://github.com/fivexl/golang-radius-server-ldap-with-mfa) | `string` | `v0.0.2` | no |
| softether_vpnserver_version | Version of Softether VPN Server | `string` | `v4.34-9745-beta` | no |
| softether_vpnserver_release_date | Release Date of Softether VPN Server | `string` | `2020.04.05` | no |

## Ubuntu Client Demo setup
- `sudo apt install network-manager-l2tp-gnome -y`
- Settings -> Network -> Add VPN -> Layer 2 Tunneling Protocol (L2TP)
- gateway: tf ${vpn_dns}
- User Auth
  - User Name: user in LDAP (e: realuser)
  - Password: pass in LDAP
- Enable IPsec tunnel to L2TP host
- Pre-shared key: tf ${vpn_ipsec_psk}
- Phase 1 algos: aes256-sha1-modp2048,aes128-sha1-modp2048
- Phase 2 algos: aes256-sha1,aes128-sha1
- Add routes. Ubuntu default client doesn't support DHCP Classless Static Routes
- Enable "Use this connection only for resources on its network" in case of `enable_dhcp_gw` = `false` or if split routing is required. 

Guide with pictures [here](https://help.vpntunnel.com/support/solutions/articles/5000782608-vpntunnel-l2tp-installation-guide-for-ubuntu-18-04-)

## How to Test private DNS zone
- Double check `enableDnsHostnames` and `enableDnsSupport`: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html
- Connect VPN
- Add record to private DNS zone
- Try to resolve: nslookup test-record.private-zone.your-domain.com

## WebGUI
- SoftEther VPN Server HTML5 Ajax-based Web Administration Console (Under construction!)
- Available on `vpn_admin_port` (`5555` by default)


## VPN TODO
- Add DUO support
