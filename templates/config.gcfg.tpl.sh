#!/bin/bash
sudo tee "${FILE_PATH}" > /dev/null <<EOL
[Radius]
Listen=127.0.0.1:1812
Secret="${RADIUS_SECRET}"
[LDAP]
Addr="${LDAP_ADDR}"
UserDN="${USER_DN}"
[DUO]
Enabled=${DUO_ENABLED}
IKey=${DUO_IKEY}
SKey=${DUO_SKEY}
APIHost=${DUO_API_HOST}
TimeOut=${DUO_TIME_OUT}
EOL