# softether-radius-vpn
Softether based VPN with LDAP/MFA auth via RADIUS

# Packer variables
- aws_profile - AWS_PROFILE for build and store AMI
- project_name - Name of project for AMI name, AMI and Snapshot tags
- ami_region - AWS_DEFAULT_REGION where AMI will builds and stored
- kms_key_id - AWS KMS key for encrypt storage volume

# Terraform variables
- region - AWS region where resources will be created
- project_name - Name of project for SH, CW, Tags and etc
- dns_zone_name - Zone name for your VPN server
- tags - map your tags (e.g. {"tag_name": "tag_value"})
- cloudwatch_loggroup_retention (e.g.: 1)
- instance_type - AWS instance type (e.g. t3a.micro)
- spot_price - unused
- associate_public_ip_address - Does your instance need public IP?
- key_pair_name - key for SSH access
- root_block_kms_key_arn - ARN of the KMS Key for encrypting the volume
- vpc_id - ID of your VPC (e.g.: vpc-fb648686123456)
- public_subnet_tags - tags for search public subnets in your VPC
- target_cidr - Target CIDR (inside your VPC or all VPC CIDR) (e.g. 10.0.0.0/16)
- vpn_cidr - Will be used for VPN network. .1 - GW, .10-.200 - IPs (e.g. : 172.17.0.0/24) 
- vpn_admin_port - Port for admin access to VPC software
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
- Enforce UDP encapsulation