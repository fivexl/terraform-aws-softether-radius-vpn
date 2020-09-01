#!/bin/bash
sudo tee "${FILE_PATH}" > /dev/null <<EOL
Hub DEFAULT
UserCreate * /GROUP:none /REALNAME:"Radius" /NOTE:"Used for Radius/MFA Auth"
UserList
RadiusServerSet localhost:1812 /SECRET:"${RADIUS_SECRET}" /RETRY_INTERVAL:10000
RadiusServerGet
SecureNatEnable
DhcpSet /START:192.168.30.10 /END:192.168.30.200 /MASK:255.255.255.0 /EXPIRE:7200 /GW:192.168.30.1 /DNS:192.168.30.1 /DNS2:1.1.1.1 /DOMAIN:none /LOG:yes /PUSHROUTE:""${PUSH_ROUTE}""
DhcpGet
IPsecEnable /L2TP:yes /L2TPRAW:no /ETHERIP:no /PSK:"${PSK}" /DEFAULTHUB:default
IPsecGet
ServerPasswordSet "${SERVER_PASSWORD}"
ListenerDisable 443
ListenerDisable 992
ListenerDisable 1194
Flush
EOL