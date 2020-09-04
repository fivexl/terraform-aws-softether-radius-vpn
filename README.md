# softether-radius-vpn
Softether based VPN with LDAP/MFA auth via RADIUS

# VPN TODO
- Add DUO support

# Packer variables
- aws_profile - AWS_PROFILE for build and store AMI
- name - Name for AMI, builder, snapshot names
- ami_region - AWS_DEFAULT_REGION where AMI will builds and stored

# Terraform TODO
- not supported: module count>1 
- not supported: aws_spot_instance_request support

# Terraform variables
- name - The name used for logs, sg, iam (default: softether-radius-vpn)
- tags - map your tags (e.g. {"tag_name": "tag_value"})
- create_logs - If you need cloudwatch logs (default: true)
- log_retention_days (default: 90, use with create_logs: true)
- create_dns - If you need VPN DNS (default: true)
- dns_zone_name - Name of Public DNS zone where record will be 
- dns_a_record - Name of A record in DNS zone (default: vpn)
- ami_name_prefix - For search AMI (default: softether-radius-vpn) 
- ami_owner - Owner of AMI for search (default: self)
- vpc_id - ID of your VPC (e.g.: vpc-fb648686123456)
- public_subnet_tags - tags for search public subnets in your VPC (default: { "Type" : "Public" })
- instance_type - AWS instance type (default: t3a.micro)
- spot_price - unused
- key_pair_name - key for SSH access
- ebs_encrypt - For encrypt EBS root volume (default: true)
- root_block_kms_key_arn - ARN of the KMS Key for encrypting the volume (use with ebs_encrypt)
- target_cidr - Target CIDR (inside your VPC or all VPC CIDR) (e.g. 10.0.0.0/16)
- vpn_cidr - Will be used for VPN network. .1 - GW, .10-.200 - IPs (default : 172.16.0.0/24) 
- vpn_admin_port - Port for admin access to VPC software (default: 5555)
- ldap_addr - Your LPAD for Auth (e.g. ldaps://ldap.jumpcloud.com:636)
- ldap_user_dn - Your USER_DN in LDAP (e.g.: uid={{username}},ou=users,o=****,dc=jumpcloud,dc=com)
- duo_enabled - DUO support true/false

# Ubuntu Client Demo setup
- Add VPN  
- Layer 2 Tunneling Protocol (L2TP)  
- gateway: tf ${vpn_dns}
- User Auth
  - User Name: user in LDAP (e: realuser)
  - Password: pass in LDAP
- Enable IPsec tunnel to L2TP host
- Pre-shared key: tf ${vpn_ipsec_psk}
- Add routes. Ubuntu default client doesn't support DHCP Classless Static Routes