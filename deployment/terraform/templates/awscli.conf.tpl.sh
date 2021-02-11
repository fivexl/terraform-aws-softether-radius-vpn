#!/bin/bash
sudo tee "${FILE_PATH}" > /dev/null <<EOL
[plugins]
cwlogs = cwlogs
[default]
region = ${REGION}
EOL