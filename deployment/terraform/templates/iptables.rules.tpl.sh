#!/bin/bash
sudo tee "${FILE_PATH}" > /dev/null <<EOL
*nat
-A POSTROUTING -s ${VPN_CIDR} -d "${TARGET_CIDR}" -j MASQUERADE
COMMIT
EOL