#!/bin/bash
sudo tee "${FILE_PATH}" > /dev/null <<EOL
*nat
-A POSTROUTING -s 192.168.30.0/24 -d "${TARGET_CIDR}" -j MASQUERADE
COMMIT
EOL