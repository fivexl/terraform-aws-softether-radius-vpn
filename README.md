# softether-radius-vpn
Softether based VPN with LDAP/MFA auth via RADIUS

# Packer variables
- aws_profile - AWS_PROFILE for build and store AMI
- project_name - Name of project for AMI name, AMI and Snapshot tags
- ami_region - AWS_DEFAULT_REGION where AMI will builds and stored
- kms_key_id - AWS KMS key for encrypt storage volume

# Input variables
- vpc_id - ID of your VPC (e.g.: vpc-fb648686123456)
- dns_zone_name - Zone name for your VPN server
- instance_type - AWS instance type (e.g. t2.micro)
- push_route  - Route for VPN (e.g. 172.31.0.0/255.255.0.0/192.168.30.1)
- target_cidr - Target CIDR (e.g. 172.31.0.0/16)
- ldap_addr - Your LPAD for Auth (e.g. ldaps://ldap.jumpcloud.com:636)
- ldap_user_dn - Your USER_DN in LDAP (e.g.: uid={{username}},ou=users,o=****,dc=jumpcloud,dc=com)
- duo_enabled - DUO support true/false
- tags - map your tags (e.g. {"tag_name": "tag_value"})
- cloudwatch_loggroup_name   (e.g.: cloudwatch_loggroup_name)
- cloudwatch_loggroup_retention (e.g.: 1)

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