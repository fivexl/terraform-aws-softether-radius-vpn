#!/bin/bash
sudo tee "${FILE_PATH}" > /dev/null <<EOL
[general]
state_file = /etc/awslogs/state

[/usr/local/rserver/logs]
datetime_format = %b %d %H:%M:%S
file = /usr/local/rserver/logs
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = ${RSERVER_LOG}

[/usr/vpnserver/security_log/DEFAULT]
datetime_format = %b %d %H:%M:%S
file = /usr/vpnserver/security_log/DEFAULT/sec_*
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = ${VPN_SERVER_LOG}

[/usr/vpnserver/server_log]
datetime_format = %b %d %H:%M:%S
file = /usr/vpnserver/server_log/vpn_*
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = ${VPN_SECURITY_LOG}
EOL