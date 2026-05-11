#!/bin/bash
# log-rotate.sh - install logrotate config for republicd journal
set -e
cat > /etc/logrotate.d/republicd << 'CONF'
/var/log/republicd/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    sharedscripts
}
CONF
echo "Installed. Test with: logrotate -d /etc/logrotate.d/republicd"
