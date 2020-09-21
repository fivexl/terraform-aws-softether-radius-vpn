#!/bin/bash
sudo tee "${FILE_PATH}" > /dev/null <<EOL
Hub DEFAULT
UserCreate * /GROUP:none /REALNAME:"Radius" /NOTE:"Used for Radius/MFA Auth"
UserList
BridgeCreate DEFAULT /DEVICE:sevpn /TAP:yes
BridgeDeviceList
BridgeList
RadiusServerSet localhost:1812 /SECRET:"${RADIUS_SECRET}" /RETRY_INTERVAL:10000
RadiusServerGet
SecureNatHostSet /MAC:none /IP:${DHCP_GW} /MASK:${DHCP_MASK}
SecureNatHostGet
DhcpSet /START:${DHCP_START} /END:${DHCP_END} /MASK:${DHCP_MASK} /EXPIRE:7200 /GW:${DHCP_GW} /DNS:${DHCP_DNS} /DNS2:1.0.0.1 /DOMAIN:${DOMAIN} /LOG:yes /PUSHROUTE:"${PUSH_ROUTE}"
DhcpGet
IPsecEnable /L2TP:yes /L2TPRAW:no /ETHERIP:no /PSK:"${PSK}" /DEFAULTHUB:default
IPsecGet
ServerPasswordSet "${SERVER_PASSWORD}"
ListenerDisable 443
ListenerDisable 992
ListenerDisable 1194
SecureNatEnable
SecureNatStatusGet
Flush
EOL